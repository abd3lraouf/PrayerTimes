import Foundation
import ServiceManagement

struct StartupManager {
    /// Sync UserDefaults with actual system login item state (e.g. user removed it via System Settings).
    static func syncLoginItemState() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        UserDefaults.standard.set(isEnabled, forKey: StorageKeys.launchAtLogin)
    }

    /// Returns true if the system state was updated successfully.
    static func toggleLaunchAtLogin(isEnabled: Bool) -> Bool {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            #if DEBUG
            print("Failed to update launch at login setting: \(error.localizedDescription)")
            #endif
            return false
        }
    }
}
