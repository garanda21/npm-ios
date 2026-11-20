import SwiftUI

struct ProxyHealthLabel: View {
    let health: ProxyHealth

    var body: some View {
        Label {
            Text(health.title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: health.symbol)
                .foregroundStyle(health.tint)
        }
        .font(.caption.weight(.semibold))
    }
}

extension ProxyHealth {
    var tint: Color {
        switch self {
        case .active: .green
        case .error: .red
        case .disabled: .orange
        case .unknown: .secondary
        }
    }
}
