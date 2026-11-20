import SwiftUI

struct DashboardInventory: View {
    let report: ReportHost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host inventory")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            DashboardGrid {
                tile("PROXY_HOSTS", symbol: "bolt", count: report.proxy)
                tile("REDIRECTION_HOSTS", symbol: "arrow.trianglehead.branch", count: report.redirection)
                tile("STREAMS", symbol: "dot.radiowaves.left.and.right", count: report.stream)
                tile("404_HOSTS", symbol: "bolt.slash", count: report.dead)
            }
        }
    }

    private func tile(_ title: LocalizedStringKey, symbol: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(count, format: .number)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
