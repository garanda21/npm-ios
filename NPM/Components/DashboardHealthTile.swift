import SwiftUI

struct DashboardHealthTile: View {
    let health: ProxyHealth
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if #available(iOS 26, *) {
                tile.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            } else {
                tile.background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            }
        }
        .buttonStyle(.plain)
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: 7) {
            ProxyHealthLabel(health: health)
            Group {
                if let count {
                    Text(count, format: .number)
                } else {
                    Text("—")
                        .accessibilityLabel("Count unavailable")
                }
            }
            .font(.title.bold())
            .monospacedDigit()
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .contentShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
