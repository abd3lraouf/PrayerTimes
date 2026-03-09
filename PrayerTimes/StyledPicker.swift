import SwiftUI

struct StyledPicker<SelectionValue: Hashable, Content: View>: View {
    let label: LocalizedStringKey
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Picker("", selection: $selection, content: content)
                .fixedSize()
        }
    }
}
