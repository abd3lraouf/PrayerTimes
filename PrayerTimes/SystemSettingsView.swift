import SwiftUI
import NavigationStack

struct SystemSettingsView: View {
    static let id = "SystemSettingsStack"
    
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var isHeaderHovering = false

    private var viewWidth: CGFloat {
        return vm.useCompactLayout ? 220 : 260
    }

    var body: some View {
        NavigationStackView(Self.id) {
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    navigationModel.hideView(SettingsView.id, animation: vm.backwardAnimation())
                }) {
                    HStack {
                        Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("System").font(.body).fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(isHeaderHovering ? Color("HoverColor") : .clear).cornerRadius(5)
                }.buttonStyle(.plain).padding(.horizontal, 5).padding(.top, 2).onHover { hovering in isHeaderHovering = hovering }
                
                Rectangle()
                    .fill(Color("DividerColor"))
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 12) {
                    Text("System").font(.caption).foregroundColor(Color("SecondaryTextColor"))
                    StyledToggle(label: "Run at Login", isOn: $launchAtLogin)
                    
                    HStack {
                        Text("Animation Style").font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.animationType) {
                            ForEach(AnimationType.allCases) { type in
                                Text(type.localized).tag(type)
                            }
                        }.fixedSize()
                    }
                }
                .controlSize(.small)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .frame(width: viewWidth)
        }
    }
}
