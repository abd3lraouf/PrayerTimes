import SwiftUI
import NavigationStack

struct FastingModeSettingsView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var fastingManager: FastingModeManager
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection
    @State private var isHeaderHovering = false

    @AppStorage(StorageKeys.suhoorPreAlertMinutes) private var suhoorPreAlertMinutes: Int = 30
    @AppStorage(StorageKeys.iftarNotificationEnabled) private var iftarNotificationEnabled: Bool = true
    @AppStorage(StorageKeys.duaRemindersEnabled) private var duaRemindersEnabled: Bool = false
    @AppStorage(StorageKeys.taraweehReminderEnabled) private var taraweehReminderEnabled: Bool = false
    @AppStorage(StorageKeys.taraweehMinutesAfterIsha) private var taraweehMinutesAfterIsha: Int = 30

    private var viewWidth: CGFloat { vm.useCompactLayout ? 220 : 260 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                navigationModel.hideView(SettingsView.id, animation: vm.backwardAnimation())
            }) {
                HStack {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Fasting Mode").font(.body).fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 5).padding(.horizontal, 8)
                .background(isHeaderHovering ? Color("HoverColor") : .clear).cornerRadius(5)
            }
            .buttonStyle(.plain).padding(.horizontal, 5).padding(.top, 2)
            .onHover { hovering in isHeaderHovering = hovering }

            Rectangle()
                .fill(Color("DividerColor"))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    StyledToggle(label: "Fasting Mode", isOn: $fastingManager.isFastingModeEnabled)
                    StyledToggle(label: "Auto-detect Ramadan", isOn: $fastingManager.isAutoDetectEnabled)

                    Rectangle().fill(Color("DividerColor")).frame(height: 0.5)

                    Text("Notifications").font(.caption).foregroundColor(Color("SecondaryTextColor"))

                    HStack {
                        Text("Suhoor Alert").font(.subheadline)
                        Spacer()
                        Picker("", selection: $suhoorPreAlertMinutes) {
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("60 min").tag(60)
                        }.fixedSize()
                    }

                    StyledToggle(label: "Iftar Notification", isOn: $iftarNotificationEnabled)
                    StyledToggle(label: "Dua Reminders", isOn: $duaRemindersEnabled)
                    StyledToggle(label: "Taraweeh Reminder", isOn: $taraweehReminderEnabled)

                    if taraweehReminderEnabled {
                        HStack {
                            Text("After Isha").font(.subheadline)
                            Spacer()
                            Picker("", selection: $taraweehMinutesAfterIsha) {
                                Text("15 min").tag(15)
                                Text("30 min").tag(30)
                                Text("45 min").tag(45)
                                Text("60 min").tag(60)
                            }.fixedSize()
                        }
                    }
                }
                .controlSize(.small)
                .padding(.horizontal, 16).padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .frame(width: viewWidth)
    }
}
