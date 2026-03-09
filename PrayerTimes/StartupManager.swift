import Foundation
import ServiceManagement

struct StartupManager {
    static func toggleLaunchAtLogin(isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            #if DEBUG
            print("Failed to update launch at login setting: \(error.localizedDescription)")
            #endif
        }
    }
}
