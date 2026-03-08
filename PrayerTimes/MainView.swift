import SwiftUI
import Adhan
import NavigationStack

struct MainView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var navigationModel: NavigationModel
    @EnvironmentObject var hijriManager: HijriCalendarManager
    @Environment(\.layoutDirection) var layoutDirection
    @State private var isSettingsHovering = false
    @State private var isAboutHovering = false
    @State private var isCalendarHovering = false
    @State private var isQuitHovering = false
    private var viewWidth: CGFloat { return vm.useCompactLayout ? 220 : 260 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PrayerTimes").font(.system(size: 13, weight: .semibold))
                Spacer()
                if vm.isPrayerDataAvailable && vm.menuBarTextMode == .hidden {
                    let format = NSLocalizedString("prayer_in_countdown", comment: "")
                    let localizedPrayerName = NSLocalizedString(vm.nextPrayerName, comment: "")
                    Text(String(format: format, localizedPrayerName, vm.countdown))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(vm.isPrayerImminent ? .red : Color("SecondaryTextColor"))
                        .transition(.opacity.animation(.easeInOut))
                }
            }
            .padding(.horizontal, 12).padding(.top, 4)

            Rectangle()
                .fill(Color("DividerColor"))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            if vm.isPrayerDataAvailable {
                FastingBannerView()
                PrayerListView()
            } else {
                Spacer()
                PermissionRequestView()
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color("DividerColor"))
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)

                Button(action: {
                    navigationModel.showView(ContentView.id, animation: vm.forwardAnimation()) { SettingsView() }
                }) {
                    HStack {
                        Text("Settings").font(.system(size: 13))
                        Spacer();
                        Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                        .padding(.vertical, 5).padding(.horizontal, 8)
                        .background(isSettingsHovering ? Color("HoverColor") : .clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 5)
                .onHover { hovering in isSettingsHovering = hovering }
                .focusable(false)
                .accessibilityIdentifier("MainView.settingsButton")

                Button(action: {
                    navigationModel.showView(ContentView.id, animation: vm.forwardAnimation()) { HijriCalendarView() }
                }) {
                    HStack {
                        Text("Hijri Calendar");
                        Spacer();
                        Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                        .padding(.vertical, 5).padding(.horizontal, 8)
                        .background(isCalendarHovering ? Color("HoverColor") : .clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 5)
                .onHover { hovering in isCalendarHovering = hovering }
                .focusable(false)
                .accessibilityIdentifier("MainView.calendarButton")

                Button(action: {
                    navigationModel.showView(ContentView.id, animation: vm.forwardAnimation()) { AboutView() }
                }) {
                    HStack {
                        Text("About").font(.system(size: 13))
                        Spacer();
                        Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                        .padding(.vertical, 5).padding(.horizontal, 8)
                        .background(isAboutHovering ? Color("HoverColor") : .clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 5)
                .onHover { hovering in isAboutHovering = hovering }
                .focusable(false)
                .accessibilityIdentifier("MainView.aboutButton")

                Rectangle()
                    .fill(Color("DividerColor"))
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)

                Button(action: { NSApp.terminate(nil) }) {
                    HStack { Text("Quit").font(.system(size: 13)); Spacer() }
                        .padding(.vertical, 5).padding(.horizontal, 8)
                        .background(isQuitHovering ? Color("HoverColor") : .clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 5)
                .onHover { hovering in isQuitHovering = hovering }
                .focusable(false)
            }
        }.padding(.vertical, 8).frame(width: viewWidth)
    }
}

// MARK: - Fasting Colors

enum FastingColors {
    static let suhoor = Color("SuhoorColor")
    static let suhoorBg = Color("SuhoorBgColor")
    static let iftar = Color("IftarColor")
    static let iftarBg = Color("IftarBgColor")
    static let banner = Color("FastingBannerColor")
    static let bannerBg = Color("FastingBannerBgColor")
}

// MARK: - Prayer List

struct PrayerListView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var hijriManager: HijriCalendarManager
    @EnvironmentObject var fastingManager: FastingModeManager
    @AppStorage(StorageKeys.taraweehReminderEnabled) private var taraweehReminderEnabled: Bool = false
    @AppStorage(StorageKeys.taraweehMinutesAfterIsha) private var taraweehMinutesAfterIsha: Int = 30
    private var prayerOrder: [String] {
        let defaultOrder = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        let sunnahOrder = ["Tahajud", "Fajr", "Dhuha", "Dhuhr", "Asr", "Maghrib", "Isha"]
        let baseOrder = vm.showSunnahPrayers ? sunnahOrder : defaultOrder
        return baseOrder.filter { vm.todayTimes.keys.contains($0) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill").font(.system(size: 9))
                Text(vm.locationStatusText).font(.system(size: 11))
                Spacer()
            }
            .foregroundColor(Color("SecondaryTextColor")).padding(.horizontal, 12)

            if vm.isUsingManualLocation && !vm.locationInfoText.isEmpty {
                Text(vm.locationInfoText)
                    .font(.system(size: 10))
                    .foregroundColor(Color("SecondaryTextColor"))
                    .padding(.horizontal, 12).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HijriDateBadge(hijriManager: hijriManager)
            VStack(spacing: 1) {
                ForEach(prayerOrder, id: \.self) { prayerName in
                    if let prayerTime = vm.todayTimes[prayerName] {
                        let isNextPrayer = prayerName == vm.nextPrayerName
                        let (highlightColor, textColor): (Color, Color) = {
                            if isNextPrayer && vm.isPrayerImminent {
                                if vm.useAccentColor {
                                    return (Color.red, Color.white)
                                } else {
                                    return (Color("HighlightColor"), .red)
                                }
                            }
                            else if isNextPrayer {
                                if vm.useAccentColor {
                                    return (Color.accentColor, Color.white)
                                } else {
                                    return (Color("HoverColor"), .primary)
                                }
                            }
                            else { return (.clear, .primary) }
                        }()
                        PrayerRow(
                            prayerName: prayerName,
                            prayerTime: prayerTime,
                            isNextPrayer: isNextPrayer,
                            isHighlighted: isNextPrayer,
                            highlightColor: highlightColor,
                            textColor: textColor,
                            fastingManager: fastingManager,
                            dateFormatter: vm.dateFormatter
                        )

                        // Show Taraweeh time after Isha when fasting mode active
                        if prayerName == "Isha" && fastingManager.isFastingModeEnabled && taraweehReminderEnabled,
                           let taraweeh = fastingManager.taraweehTime(from: vm.todayTimes, minutesAfterIsha: taraweehMinutesAfterIsha) {
                            HStack {
                                Text(LocalizedStringKey("Taraweeh"))
                                    .font(.system(size: 13))
                                Spacer()
                                Text("Around").font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                Text(vm.dateFormatter.string(from: taraweeh))
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                        }
                    }
                }
            }.padding(.horizontal, 5).padding(.top, 4)
        }
    }
}

// MARK: - Prayer Row

struct PrayerRow: View {
    let prayerName: String
    let prayerTime: Date
    let isNextPrayer: Bool
    let isHighlighted: Bool
    let highlightColor: Color
    let textColor: Color
    let fastingManager: FastingModeManager
    let dateFormatter: DateFormatter

    private var fastingLabel: String? {
        guard fastingManager.isFastingModeEnabled, fastingManager.currentFastingDay != nil else { return nil }
        if prayerName == "Fajr" { return "Suhoor" }
        if prayerName == "Maghrib" { return "Iftar" }
        return nil
    }

    private var fastingColor: Color {
        prayerName == "Fajr" ? FastingColors.suhoor : FastingColors.iftar
    }

    private var fastingBgColor: Color {
        prayerName == "Fajr" ? FastingColors.suhoorBg : FastingColors.iftarBg
    }

    private var rowBackground: Color {
        if isHighlighted { return highlightColor }
        if fastingLabel != nil { return fastingBgColor }
        return .clear
    }

    var body: some View {
        HStack(spacing: 0) {
            if let label = fastingLabel {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isNextPrayer ? textColor : fastingColor)
                Text(" / ")
                    .font(.system(size: 11))
                    .foregroundColor(isNextPrayer ? textColor.opacity(0.5) : Color("SecondaryTextColor"))
            }
            Text(LocalizedStringKey(prayerName))
                .font(.system(size: 13, weight: isNextPrayer ? .semibold : (fastingLabel != nil ? .medium : .regular)))
            Spacer()
            if prayerName == "Tahajud" || prayerName == "Dhuha" {
                Text("Around")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isNextPrayer ? textColor.opacity(0.7) : Color("SecondaryTextColor"))
                    .padding(.trailing, 4)
            }
            Text(dateFormatter.string(from: prayerTime))
                .font(.system(size: 13, weight: isNextPrayer ? .semibold : .regular, design: .monospaced))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(rowBackground))
    }
}

// MARK: - Fasting Banner

struct FastingBannerView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var fastingManager: FastingModeManager

    var body: some View {
        if fastingManager.isFastingModeEnabled, let day = fastingManager.currentFastingDay {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11))
                        .foregroundColor(FastingColors.banner)
                    Text(String(format: NSLocalizedString("fasting_day_counter", comment: ""), day, fastingManager.totalFastingDays))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }

                HStack(spacing: 14) {
                    if let suhoor = fastingManager.suhoorTime(from: vm.todayTimes) {
                        HStack(spacing: 3) {
                            Image(systemName: "sunrise.fill")
                                .font(.system(size: 9))
                            Text(vm.dateFormatter.string(from: suhoor))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(FastingColors.suhoor)
                    }
                    if let iftar = fastingManager.iftarTime(from: vm.todayTimes) {
                        HStack(spacing: 3) {
                            Image(systemName: "sunset.fill")
                                .font(.system(size: 9))
                            Text(vm.dateFormatter.string(from: iftar))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(FastingColors.iftar)
                    }
                }

                if fastingManager.isLastTenNights {
                    Text(NSLocalizedString("last_ten_nights_message", comment: ""))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FastingColors.bannerBg)
            )
            .padding(.horizontal, 5)
        }
    }
}

// MARK: - Permission Request

struct PermissionRequestView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @State private var isManualHovering = false
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.circle.fill").font(.system(size: 28)).foregroundColor(.secondary)
            Text("Location Required").font(.system(size: 14, weight: .semibold))
            Text("To provide accurate prayer times, PrayerTimes Pro needs to know your location.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("SecondaryTextColor"))
                .padding(.horizontal)
            VStack(spacing: 8) {
                if vm.isRequestingLocation {
                    ProgressView().padding(.vertical, 4)
                    Text("Requesting Permission...").font(.system(size: 11)).foregroundColor(.secondary)
                } else if vm.authorizationStatus == .denied {
                    Button("Open System Settings", action: vm.openLocationSettings).buttonStyle(.borderedProminent).controlSize(.regular)
                } else {
                    Button("Allow Location Access", action: vm.requestLocationPermission).buttonStyle(.borderedProminent).controlSize(.regular)
                }
                Button(action: {
                    navigationModel.showView(ContentView.id, animation: vm.forwardAnimation()) { ManualLocationView(isModal: true) }
                }) {
                    Text("Or, set location manually")
                        .font(.system(size: 12))
                        .padding(.vertical, 3).padding(.horizontal, 8)
                        .background(isManualHovering ? Color("HoverColor") : .clear)
                        .cornerRadius(5)
                }.buttonStyle(.plain).onHover { hovering in isManualHovering = hovering }
            }.padding(.top, 4).padding(.horizontal).animation(.easeInOut, value: vm.isRequestingLocation)
        }.frame(maxWidth: .infinity)
    }
}

struct HijriDateBadge: View {
    @ObservedObject var hijriManager: HijriCalendarManager

    var body: some View {
        let now = Date()
        let components = hijriManager.hijriDate(from: now)
        let dateString = hijriManager.hijriDateString(from: now)
        let todayEvents = IslamicEvents.events(forMonth: components.month ?? 0, day: components.day ?? 0)

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(dateString)
                Spacer()
            }
            .font(.caption)
            .foregroundColor(Color("SecondaryTextColor"))

            if let event = todayEvents.first {
                HStack(spacing: 4) {
                    Circle().fill(Color.accentColor).frame(width: 5, height: 5)
                    Text(event.localizedName).font(.caption2).foregroundColor(.accentColor)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
    }
}
