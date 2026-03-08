// MARK: - GANTI SELURUH FILE: LocationAndCalcSettingsView.swift

import SwiftUI
import NavigationStack

struct LocationAndCalcSettingsView: View {
    static let id = "LocationAndCalcSettingsStack"
    
    @EnvironmentObject var vm: PrayerTimeViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.layoutDirection) var layoutDirection
    @State private var isHeaderHovering = false

    private var viewWidth: CGFloat {
        return vm.useCompactLayout ? 280 : 330
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
                        Text("Calculation & Location").font(.body).fontWeight(.bold)
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
                        Group {
                            Text("Calculation").font(.caption).foregroundColor(Color("SecondaryTextColor"))
                            HStack { Text("Method").font(.subheadline); Spacer(); Picker("", selection: $vm.method) { ForEach(PrayerTimesCalculationMethod.allCases) { method in Text(method.localizedName).tag(method) } } }
                            if let suggested = vm.suggestedMethod {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                        Text(String(format: NSLocalizedString("method_suggestion", comment: ""), suggested.localizedName))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(spacing: 8) {
                                        Button(NSLocalizedString("Switch", comment: "")) {
                                            vm.acceptSuggestedMethod()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        Button(NSLocalizedString("Keep Current", comment: "")) {
                                            vm.dismissSuggestedMethod()
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(8)
                                .background(Color.accentColor.opacity(0.08))
                                .cornerRadius(6)
                            }
                            HStack { Text("Time Correction").font(.subheadline); Spacer(); Button("Adjust") { navigationModel.showView(Self.id, animation: vm.forwardAnimation()) { PrayerTimeCorrectionView() } }.buttonStyle(.bordered) }
                            StyledToggle(label: "Hanafi Madhhab (for Asr)", isOn: $vm.useHanafiMadhhab)
                        }
                        Rectangle().fill(Color("DividerColor")).frame(height: 0.5)
                        Group {
                            Text("Location").font(.caption).foregroundColor(Color("SecondaryTextColor"))
                            HStack { Image(systemName: vm.isUsingManualLocation ? "pencil.circle.fill" : "location.circle.fill").foregroundColor(.secondary); Text(vm.isUsingManualLocation ? "\(NSLocalizedString("Manual:", comment: "")) \(vm.locationStatusText)" : "\(NSLocalizedString("Automatic:", comment: "")) \(vm.locationStatusText)") }.lineLimit(1).truncationMode(.tail)
                            HStack { Button("Change Manual Location") { navigationModel.showView(Self.id, animation: vm.forwardAnimation()) { ManualLocationView(isModal: false) } }.buttonStyle(.bordered); Spacer(); if vm.isUsingManualLocation { Button("Use Automatic") { vm.switchToAutomaticLocation() }.buttonStyle(.bordered) } }
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
}
