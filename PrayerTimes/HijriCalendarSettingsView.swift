import SwiftUI
import NavigationStack

struct HijriCalendarSettingsView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var hijriManager: HijriCalendarManager
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection

    @AppStorage(StorageKeys.islamicEventNotifications) private var eventNotifications = true
    @State private var isHeaderHovering = false

    private var viewWidth: CGFloat {
        vm.useCompactLayout ? 220 : 260
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                navigationModel.hideView(SettingsView.id, animation: vm.backwardAnimation())
            }) {
                HStack {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Hijri Calendar").font(.body).fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 5).padding(.horizontal, 8)
                .background(isHeaderHovering ? Color("HoverColor") : .clear).cornerRadius(5)
            }
            .buttonStyle(.plain).padding(.horizontal, 5).padding(.top, 2)
            .onHover { hovering in isHeaderHovering = hovering }

            Rectangle().fill(Color("DividerColor")).frame(height: 0.5).padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 12) {
                // Calendar type picker
                HStack {
                    Text("Calendar Type").font(.subheadline)
                    Spacer()
                    Picker("", selection: $hijriManager.selectedCalendarType) {
                        ForEach(HijriCalendarType.allCases) { type in
                            Text(type.localized).tag(type)
                        }
                    }
                    .fixedSize()
                }

                // Day correction stepper
                HStack {
                    Text("Day Correction").font(.subheadline)
                    Spacer()
                    PrayerTimesStepper(
                        value: Binding(
                            get: { Double(hijriManager.manualDayCorrection) },
                            set: { hijriManager.manualDayCorrection = Int($0) }
                        ),
                        range: -2...2,
                        step: 1
                    )
                }

                Text("Adjust if the Hijri date doesn't match your local moon sighting.")
                    .font(.caption2)
                    .foregroundColor(Color("SecondaryTextColor"))

                Rectangle().fill(Color("DividerColor")).frame(height: 0.5)

                // Event notifications toggle
                StyledToggle(label: "Islamic Event Notifications", isOn: $eventNotifications)
                    .onChange(of: eventNotifications) { newValue in
                        if newValue {
                            NotificationManager.scheduleIslamicEventNotifications(hijriManager: hijriManager)
                        } else {
                            NotificationManager.cancelIslamicEventNotifications()
                        }
                    }

                // Preview of current Hijri date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(hijriManager.hijriDateString(from: Date()))
                }
                .font(.caption)
                .foregroundColor(Color("SecondaryTextColor"))
            }
            .controlSize(.small)
            .padding(.horizontal, 16).padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(width: viewWidth)
    }
}
