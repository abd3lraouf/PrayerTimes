import SwiftUI
import NavigationStack
import UserNotifications

struct NotificationsSettingsView: View {
    @EnvironmentObject var notificationSettings: NotificationSettings
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection
    @State private var isHeaderHovering = false
    @State private var notificationPermissionDenied = false

    private let mainPrayers = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
    private let allPrayers = ["Tahajud", "Fajr", "Sunrise", "Dhuha", "Dhuhr", "Asr", "Maghrib", "Isha"]

    private var prayers: [String] {
        vm.showSunnahPrayers ? allPrayers : mainPrayers
    }
    private var viewWidth: CGFloat { vm.useCompactLayout ? 350 : 400 }

    var body: some View {
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
            }
            .buttonStyle(.plain).padding(.horizontal, 5).padding(.top, 2)
            .onHover { isHeaderHovering = $0 }
            .accessibilityIdentifier("NotificationsSettingsView.backButton")

            Rectangle().fill(Color("DividerColor")).frame(height: 0.5).padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    StyledToggle(label: "Enable Prayer Notifications", isOn: $notificationSettings.prayerNotificationsEnabled)
                        .onChange(of: notificationSettings.prayerNotificationsEnabled) { _ in
                            notificationSettings.save()
                            vm.scheduleNotifications()
                        }

                    if notificationPermissionDenied && notificationSettings.prayerNotificationsEnabled {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("System notifications are disabled.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Open Settings") {
                                NSWorkspace.shared.open(NotificationManager.notificationSettingsURL)
                            }
                            .font(.caption)
                            .buttonStyle(.link)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    if notificationSettings.prayerNotificationsEnabled {
                        Text("Global Settings")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(Color("SecondaryTextColor"))

                        globalSettingsSection

                        Rectangle().fill(Color("DividerColor")).frame(height: 0.5)

                        Text("Prayer Notifications")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(Color("SecondaryTextColor"))

                        ForEach(prayers, id: \.self) { prayer in
                            PrayerNotificationRow(prayerName: prayer)
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
        .onAppear {
            NotificationManager.getAuthorizationStatus { status in
                notificationPermissionDenied = (status == .denied)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            NotificationManager.getAuthorizationStatus { status in
                notificationPermissionDenied = (status == .denied)
            }
        }
    }

    private var globalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            StyledPicker(label: "Type", selection: $notificationSettings.globalSettings.notificationType) {
                ForEach(NotificationType.allCases) { type in
                    Text(type.localized).tag(type)
                }
            }
            .onChange(of: notificationSettings.globalSettings.notificationType) { _ in
                notificationSettings.save()
                vm.scheduleNotifications()
            }

            StyledToggle(label: "System Notification", isOn: $notificationSettings.globalSettings.systemNotificationEnabled)
                .onChange(of: notificationSettings.globalSettings.systemNotificationEnabled) { _ in
                    notificationSettings.save()
                    vm.scheduleNotifications()
                }

            StyledToggle(label: "Full Screen", isOn: $notificationSettings.globalSettings.fullScreenNotificationEnabled)
                .onChange(of: notificationSettings.globalSettings.fullScreenNotificationEnabled) { _ in
                    notificationSettings.save()
                    vm.scheduleNotifications()
                }

            if notificationSettings.globalSettings.notificationType == .beforePrayer || notificationSettings.globalSettings.notificationType == .both {
                StyledPicker(label: "Remind Before", selection: $notificationSettings.globalSettings.prePrayerMinutes) {
                    ForEach(NotificationTiming.allCases) { timing in
                        Text(timing.localized).tag(timing)
                    }
                }
                .onChange(of: notificationSettings.globalSettings.prePrayerMinutes) { _ in
                    notificationSettings.save()
                    vm.scheduleNotifications()
                }
            }
        }
    }
}

struct PrayerNotificationRow: View {
    @EnvironmentObject var notificationSettings: NotificationSettings
    @EnvironmentObject var vm: PrayerTimeViewModel
    @Environment(\.layoutDirection) var layoutDirection

    let prayerName: String
    @State private var isExpanded = false

    private var settings: PrayerNotificationSettings {
        notificationSettings.settings(for: prayerName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.down" : (layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey(prayerName))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { settings.isEnabled },
                    set: { newValue in
                        var s = settings
                        s.isEnabled = newValue
                        notificationSettings.updateSettings(for: prayerName, settings: s)
                        vm.scheduleNotifications()
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Use Custom Settings").font(.caption)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { !settings.useGlobalSettings },
                            set: { useCustom in
                                var s = settings
                                s.useGlobalSettings = !useCustom
                                notificationSettings.updateSettings(for: prayerName, settings: s)
                                vm.scheduleNotifications()
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                    }

                    if !settings.useGlobalSettings {
                        StyledPicker(label: "Type", selection: Binding(
                            get: { settings.notificationType },
                            set: { newValue in
                                var s = settings
                                s.notificationType = newValue
                                notificationSettings.updateSettings(for: prayerName, settings: s)
                                vm.scheduleNotifications()
                            }
                        )) {
                            ForEach(NotificationType.allCases) { type in
                                Text(type.localized).tag(type)
                            }
                        }

                        StyledToggle(label: "System Notification", isOn: Binding(
                            get: { settings.systemNotificationEnabled },
                            set: { newValue in
                                var s = settings
                                s.systemNotificationEnabled = newValue
                                notificationSettings.updateSettings(for: prayerName, settings: s)
                                vm.scheduleNotifications()
                            }
                        ))

                        StyledToggle(label: "Full Screen", isOn: Binding(
                            get: { settings.fullScreenNotificationEnabled },
                            set: { newValue in
                                var s = settings
                                s.fullScreenNotificationEnabled = newValue
                                notificationSettings.updateSettings(for: prayerName, settings: s)
                                vm.scheduleNotifications()
                            }
                        ))

                        if settings.notificationType == .beforePrayer || settings.notificationType == .both {
                            StyledPicker(label: "Remind Before", selection: Binding(
                                get: { settings.prePrayerMinutes },
                                set: { newValue in
                                    var s = settings
                                    s.prePrayerMinutes = newValue
                                    notificationSettings.updateSettings(for: prayerName, settings: s)
                                    vm.scheduleNotifications()
                                }
                            )) {
                                ForEach(NotificationTiming.allCases) { timing in
                                    Text(timing.localized).tag(timing)
                                }
                            }
                        }
                    } else {
                        Text("Using global settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.leading, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 2)
    }
}
