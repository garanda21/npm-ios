import SwiftUI

struct ProxyRowView: View {
    let proxy: Proxy

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(proxy.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(proxy.host)
                .font(.subheadline.monospaced())
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ProxyHealthLabel(health: proxy.health)
                if proxy.domain_names.count > 1 {
                    Text("· \(proxy.domain_names.count) domains")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ProxyRowView(proxy: .fake())
}
