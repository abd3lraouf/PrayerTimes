import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}

class AppLogger {
    static let shared = AppLogger()

    private let logFileURL: URL
    private let crashFileURL: URL
    private let crashFlagURL: URL
    private let stateFileURL: URL
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "com.prayertimes.logger", qos: .utility)
    private var currentLogFileHandle: FileHandle?
    private let maxLogSize: Int64 = 5 * 1024 * 1024
    private let maxLogFiles = 5

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()

    private var logDirectory: URL {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("Logs")
    }

    private init() {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("Logs")
        logFileURL = dir.appendingPathComponent("prayertimes.log")
        crashFileURL = dir.appendingPathComponent("crashes.log")
        crashFlagURL = dir.appendingPathComponent("crash_flag")
        stateFileURL = dir.appendingPathComponent("last_state.json")

        createLogDirectoryIfNeeded()
        setupCrashHandler()
        checkForPreviousCrash()
        archiveOldLogIfNeeded()
        openLogFile()

        log("AppLogger initialized", level: .info, category: "Logger")
        log("Log file location: \(logFileURL.path)", level: .info, category: "Logger")
    }

    private func createLogDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
    }

    private func openLogFile() {
        try? currentLogFileHandle?.close()

        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil)
        }

        currentLogFileHandle = try? FileHandle(forWritingTo: logFileURL)
        currentLogFileHandle?.seekToEndOfFile()

        writeHeader()
    }

    private func writeHeader() {
        let header = """

        ════════════════════════════════════════════════════════════════
        PrayerTimes Pro - Log Session Started
        Date: \(dateFormatter.string(from: Date()))
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
        Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Device: \(Host.current().localizedName ?? "unknown")
        ════════════════════════════════════════════════════════════════

        """
        writeToFile(header)
    }

    private func archiveOldLogIfNeeded() {
        guard let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > maxLogSize else { return }

        let archiveName = "prayertimes_\(ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")).log"
        let archiveURL = logDirectory.appendingPathComponent(archiveName)

        try? currentLogFileHandle?.close()
        currentLogFileHandle = nil
        try? fileManager.moveItem(at: logFileURL, to: archiveURL)
        cleanupOldArchives()
    }

    private func cleanupOldArchives() {
        guard let logFiles = try? fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil) else { return }

        let filteredFiles = logFiles
            .filter { $0.pathExtension == "log" && $0.lastPathComponent != "prayertimes.log" && $0.lastPathComponent != "crashes.log" }
            .sorted { $0.path > $1.path }

        guard filteredFiles.count > maxLogFiles else { return }

        var files = filteredFiles

        files.removeFirst(maxLogFiles)
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Crash Detection

    private func checkForPreviousCrash() {
        // Check for signal crash flag (written by async-signal-safe handler)
        if fileManager.fileExists(atPath: crashFlagURL.path) {
            if let flagData = try? String(contentsOf: crashFlagURL, encoding: .utf8) {
                let crashLog = """

                ╔════════════════════════════════════════════════════════════════╗
                CRASH DETECTED (from signal flag)
                ╠════════════════════════════════════════════════════════════════╣
                \(flagData)
                ╚════════════════════════════════════════════════════════════════╝

                """
                writeCrashToFile(crashLog)
            }
            try? fileManager.removeItem(at: crashFlagURL)
            log("Previous signal crash detected - logged from crash flag", level: .warning, category: "CrashHandler")
        }

        if fileManager.fileExists(atPath: crashFileURL.path),
           let content = try? String(contentsOf: crashFileURL, encoding: .utf8),
           !content.isEmpty {
            log("Previous crash detected - crash log available", level: .warning, category: "CrashHandler")
        }
    }

    // MARK: - Crash Handlers

    private func setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            AppLogger.shared.handleException(exception)
        }

        setupSignalHandlers()
    }

    /// Signal handlers only use async-signal-safe operations: POSIX open/write/close + _exit.
    private func setupSignalHandlers() {
        let signalsToHandle: [Int32] = [SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP]

        for sig in signalsToHandle {
            signal(sig) { sigNum in
                // Only async-signal-safe calls here
                AppLogger.writeCrashFlag(signal: sigNum)
                // Re-raise with default handler to produce a proper crash report
                Darwin.signal(sigNum, SIG_DFL)
                Darwin.raise(sigNum)
            }
        }
    }

    /// Async-signal-safe crash flag writer. Uses only POSIX open/write/close.
    private static func writeCrashFlag(signal sigNum: Int32) {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs/crash_flag").path

        let fd = path.withCString { cPath in
            Darwin.open(cPath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        }
        guard fd >= 0 else { return }

        var msg: [UInt8] = Array("Signal: ".utf8)
        // Append signal number as ASCII digits
        var num = sigNum
        if num < 0 { num = -num }
        var digits: [UInt8] = []
        if num == 0 {
            digits.append(0x30) // '0'
        } else {
            while num > 0 {
                digits.append(UInt8(0x30 + num % 10))
                num /= 10
            }
            digits.reverse()
        }
        msg.append(contentsOf: digits)
        msg.append(0x0A) // newline

        msg.withUnsafeBufferPointer { buf in
            _ = Darwin.write(fd, buf.baseAddress, buf.count)
        }
        Darwin.close(fd)
    }

    private func handleException(_ exception: NSException) {
        let timestamp = dateFormatter.string(from: Date())
        let crashLog = """

        ╔════════════════════════════════════════════════════════════════╗
        CRASH DETECTED at \(timestamp)
        ╠════════════════════════════════════════════════════════════════╣
        Type: Exception
        Message: \(exception.reason ?? "Unknown exception")
        Name: \(exception.name.rawValue)

        Stack Trace:
        \(exception.callStackSymbols.joined(separator: "\n"))
        ╚════════════════════════════════════════════════════════════════╝

        """

        writeCrashToFile(crashLog)
        writeToFile(crashLog)
    }

    func saveAppState(_ state: [String: Any] = [:]) {
        var appState = state
        appState["lastActiveTime"] = Date().timeIntervalSince1970
        appState["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        guard let data = try? JSONSerialization.data(withJSONObject: appState, options: .prettyPrinted) else { return }
        try? data.write(to: stateFileURL)
    }

    private func writeCrashToFile(_ content: String) {
        if !fileManager.fileExists(atPath: crashFileURL.path) {
            fileManager.createFile(atPath: crashFileURL.path, contents: nil)
        }

        guard let data = content.data(using: .utf8),
              let handle = try? FileHandle(forWritingTo: crashFileURL) else { return }
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    }

    func log(_ message: String, level: LogLevel = .info, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(level.emoji) [\(level.rawValue)] [\(category)] [\(fileName):\(line)] \(function): \(message)\n"

        logQueue.async { [weak self] in
            self?.writeToFile(logEntry)
        }

        #if DEBUG
        os_log("[%{public}@] %{public}@", log: OSLog(subsystem: "com.prayertimes", category: category), type: level.osLogType, level.rawValue, message)
        #endif
    }

    private func writeToFile(_ content: String) {
        guard let data = content.data(using: .utf8) else { return }
        currentLogFileHandle?.write(data)
    }
}

extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

func log(_ message: String, level: LogLevel = .info, category: String = "App", file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.log(message, level: level, category: category, file: file, function: function, line: line)
}
