// MARK: - BUAT FILE BARU: PrayerTimes/AnimationType.swift

import Foundation
import SwiftUI

enum AnimationType: String, CaseIterable, Identifiable {
    case none = "None"
    case fade = "Fade"
    case slide = "Slide"
    
    var id: Self { self }
    
    // Properti untuk menampilkan nama yang sudah dilokalisasi di UI
    var localized: LocalizedStringKey {
        return LocalizedStringKey(self.rawValue)
    }
}
