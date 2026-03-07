// MARK: - BUAT FILE BARU: PrayerTimes/TimePreviewPopover.swift

import SwiftUI

struct TimePreviewPopover: View {
    let originalTime: Date
    let adjustedTime: Date
    let formatter: DateFormatter
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        HStack(spacing: 6) {
            Text(formatter.string(from: originalTime))
                .font(.caption)
                .foregroundColor(.secondary)
                .strikethrough(color: .secondary)

            Image(systemName: layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatter.string(from: adjustedTime))
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        // Latar belakang solid yang native dan stabil
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
        )
    }
}
