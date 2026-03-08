import SwiftUI
import NavigationStack

struct HijriCalendarView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var hijriManager: HijriCalendarManager
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection

    @State private var isHeaderHovering = false
    @State private var displayedMonth: Int = 1
    @State private var displayedYear: Int = 1447
    @State private var selectedDay: Int? = nil
    @State private var hasAppeared = false

    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    var body: some View {
        let viewWidth: CGFloat = vm.useCompactLayout ? 220 : 260

        VStack(alignment: .leading, spacing: 6) {
            // Back button
            Button(action: {
                navigationModel.hideView(ContentView.id, animation: vm.backwardAnimation())
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

            // Month/Year navigation
            HStack {
                Button(action: { navigateMonth(by: -1) }) {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)

                Spacer()
                Text("\(hijriManager.monthName(month: displayedMonth)) \(String(displayedYear))")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()

                Button(action: { navigateMonth(by: 1) }) {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 4)

            // Weekday headers
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(Color("SecondaryTextColor"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Day cells
            let daysInMonth = hijriManager.daysInMonth(month: displayedMonth, year: displayedYear)
            let firstWeekday = hijriManager.firstWeekday(month: displayedMonth, year: displayedYear)
            let todayComponents = hijriManager.hijriDate(from: Date())
            let isCurrentMonth = todayComponents.month == displayedMonth && todayComponents.year == displayedYear

            LazyVGrid(columns: columns, spacing: 2) {
                // Empty cells for offset
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Text("").frame(height: 24)
                }

                ForEach(1...daysInMonth, id: \.self) { day in
                    let isToday = isCurrentMonth && todayComponents.day == day
                    let events = IslamicEvents.events(forMonth: displayedMonth, day: day)
                    let hasEvent = !events.isEmpty
                    let isSelected = selectedDay == day

                    Button(action: { selectedDay = (selectedDay == day) ? nil : day }) {
                        VStack(spacing: 1) {
                            Text("\(day)")
                                .font(.caption)
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isToday ? .white : (isSelected ? .accentColor : .primary))
                                .frame(width: 24, height: 20)
                                .background(isToday ? Color.accentColor : (isSelected ? Color("HoverColor") : .clear))
                                .cornerRadius(4)

                            Circle()
                                .fill(hasEvent ? Color.accentColor : .clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 28)
                }
            }
            .padding(.horizontal, 12)

            // Event detail for selected day
            if let day = selectedDay {
                let events = IslamicEvents.events(forMonth: displayedMonth, day: day)
                if !events.isEmpty {
                    Rectangle().fill(Color("DividerColor")).frame(height: 0.5).padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(events) { event in
                            HStack(spacing: 6) {
                                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                                Text(event.localizedName).font(.caption).fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(width: viewWidth)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            let components = hijriManager.hijriDate(from: Date())
            displayedMonth = components.month ?? 1
            displayedYear = components.year ?? 1447
        }
    }

    private func navigateMonth(by offset: Int) {
        var newMonth = displayedMonth + offset
        var newYear = displayedYear

        if newMonth > 12 {
            newMonth = 1
            newYear += 1
        } else if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        }

        displayedMonth = newMonth
        displayedYear = newYear
        selectedDay = nil
    }
}
