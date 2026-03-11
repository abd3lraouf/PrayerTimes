import SwiftUI
import NavigationStack

struct AboutView: View {
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection

    @AppStorage(StorageKeys.showOnboardingAtLaunch) private var showOnboardingAtLaunch = true
    @State private var isHeaderHovering = false

    private var viewWidth: CGFloat {
        vm.useCompactLayout ? 280 : 330
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: handleBackButton) {
                HStack {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("About").font(.body).fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 5).padding(.horizontal, 8)
                .background(isHeaderHovering ? Color("HoverColor") : .clear)
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 5).padding(.top, 2)
            .onHover { isHeaderHovering = $0 }
            .accessibilityIdentifier("AboutView.backButton")

            Rectangle()
                .fill(Color("DividerColor"))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                        Text("PrayerTimes Pro")
                            .font(.headline)

                        Text("v\(appVersion) (\(buildNumber))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                    Text("A simple and beautiful prayer times app for your menu bar.")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryTextColor"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Rectangle()
                        .fill(Color("DividerColor"))
                        .frame(height: 0.5)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Credits")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("SecondaryTextColor"))

                        CreditCard(
                            label: "Developed by",
                            name: "abd3lraouf",
                            url: "https://github.com/abd3lraouf/PrayerTimes",
                            icon: "person.fill"
                        )

                        CreditCard(
                            label: "Based on",
                            name: "Sajda by Abrar Zha",
                            url: "https://github.com/ikoshura/Sajda",
                            icon: "star.fill"
                        )
                    }

                    Rectangle()
                        .fill(Color("DividerColor"))
                        .frame(height: 0.5)
                        .padding(.horizontal, 4)

                    StyledToggle(label: "Show Welcome Guide on Launch", isOn: $showOnboardingAtLaunch)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 8)
        .frame(width: viewWidth)
    }

    private func handleBackButton() {
        navigationModel.hideView(ContentView.id, animation: vm.backwardAnimation())
    }
}

private struct CreditCard: View {
    let label: LocalizedStringKey
    let name: String
    let url: String
    let icon: String

    @Environment(\.layoutDirection) var layoutDirection
    @State private var isHovering = false

    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                cardContent
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryTextColor"))
                }

                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Spacer()

            Image(systemName: layoutDirection == .rightToLeft ? "arrow.up.left" : "arrow.up.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color("HoverColor") : Color("HoverColor").opacity(0.3))
        )
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}
