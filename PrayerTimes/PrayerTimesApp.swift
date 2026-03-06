// MARK: - GANTI SELURUH FILE: PrayerTimes/PrayerTimesApp.swift (HAPUS @main)

import SwiftUI

// Dengan menghapus @main, kita menyerahkan kontrol peluncuran aplikasi
// ke file main.swift. Ini adalah kunci untuk stabilitas.
struct PrayerTimesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Konten di sini bisa dikosongkan.
        }
    }
}

// Ekstensi ini bisa tetap di sini atau dipindahkan ke file lain.
extension Notification.Name {
    static let popoverDidClose = Notification.Name("com.prayertimes.popoverDidClose")
    static let popoverDidOpen = Notification.Name("com.prayertimes.popoverDidOpen")
    static let prayerTimesUpdated = Notification.Name("prayerTimesUpdated")
}
