import SwiftUI
import NavigationStack

struct NotificationsSettingsView: View {
    static let id = "NotificationsSettingsStack"
    
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var notificationSettings: NotificationSettings
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection
    
    @State private var isHeaderHovering = false
    
    private var viewWidth: CGFloat {
        return vm.useCompactLayout ? 220 : 260
    }
    
    private let prayers = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
    
    var body: some View {
        NavigationStackView(Self.id) {
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    navigationModel.hideView(SettingsView.id, animation: vm.backwardAnimation())
                }) {
                    HStack {
                        Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Notifications").font(.body).fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(isHeaderHovering ? Color("HoverColor") : .clear).cornerRadius(5)
                }.buttonStyle(.plain).padding(.horizontal, 5).padding(.top, 2).onHover { hovering in isHeaderHovering = hovering }
                
                Rectangle()
                    .fill(Color("DividerColor"))
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        StyledToggle(
                            label: "Enable Prayer Notifications",
                            isOn: $notificationSettings.prayerNotificationsEnabled
                        )
                        .onChange(of: notificationSettings.prayerNotificationsEnabled) { _ in
                            notificationSettings.save()
                            vm.scheduleNotifications()
                        }
                        
                        Rectangle()
                            .fill(Color("DividerColor"))
                            .frame(height: 0.5)
                        
                        if notificationSettings.prayerNotificationsEnabled {
                            Text("Prayer Notifications")
                                .font(.caption)
                                .foregroundColor(Color("SecondaryTextColor"))
                            
                            ForEach(prayers, id: \.self) { prayer in
                                PrayerNotificationRow(
                                    prayerName: prayer,
                                    settings: binding(for: prayer)
                                )
                            }
                        }
                    }
                    .controlSize(.small)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.vertical, 8)
            .frame(width: viewWidth)
        }
    }
    
    private func binding(for prayer: String) -> Binding<PrayerNotificationSettings> {
        Binding(
            get: { notificationSettings.settings(for: prayer) },
            set: { notificationSettings.updateSettings(for: prayer, settings: $0) }
        )
    }
}

struct PrayerNotificationRow: View {
    let prayerName: String
    @Binding var settings: PrayerNotificationSettings
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey(prayerName))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                        .onChange(of: settings.isEnabled) { _ in
                            saveSettings()
                        }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded && settings.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Type").font(.caption)
                        Spacer()
                        Picker("", selection: $settings.notificationType) {
                            ForEach(NotificationType.allCases) { type in
                                Text(type.localized).tag(type)
                            }
                        }
                        .fixedSize()
                        .onChange(of: settings.notificationType) { _ in saveSettings() }
                    }
                    
                    HStack {
                        Text("Style").font(.caption)
                        Spacer()
                        Picker("", selection: $settings.notificationStyle) {
                            ForEach(NotificationStyle.allCases) { style in
                                Text(style.localized).tag(style)
                            }
                        }
                        .fixedSize()
                        .onChange(of: settings.notificationStyle) { _ in saveSettings() }
                    }
                    
                    if settings.notificationType == .beforePrayer || settings.notificationType == .both {
                        HStack {
                            Text("Remind Before").font(.caption)
                            Spacer()
                            Picker("", selection: $settings.prePrayerMinutes) {
                                ForEach(NotificationTiming.allCases) { timing in
                                    Text(timing.localized).tag(timing)
                                }
                            }
                            .fixedSize()
                            .onChange(of: settings.prePrayerMinutes) { _ in saveSettings() }
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.vertical, 4)
                .background(Color("HoverColor").opacity(0.3))
                .cornerRadius(5)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func saveSettings() {
        settings = settings
    }
}
