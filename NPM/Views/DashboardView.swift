import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appService: AppService
    @AppStorage("npm_server_url") private var instanceURL = ""

    let openProxies: (ProxyRoute) -> Void

    @State private var report: ReportHost?
    @State private var reportInstance = ""

    private var errors: [Proxy] { appService.proxies.filter { $0.health == .error } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if instanceURL.isEmpty {
                        ContentUnavailableView("Connect an instance", systemImage: "server.rack", description: Text("Add your server in Settings."))
                    } else {
                        healthSection
                        if !errors.isEmpty {
                            attentionSection
                        }
                        if let report {
                            DashboardInventory(report: report)
                        }
                    }
                }
                .frame(maxWidth: 1050)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("DASHBOARD")
            .refreshable { await reload() }
            .task(id: instanceURL) { await reload() }
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Proxy health").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("View all") { openProxies(.list(nil)) }
                    .buttonStyle(.borderless)
            }

            if appService.proxyLoadPhase == .failed {
                Label("Couldn't refresh proxy health. Pull to retry.", systemImage: "wifi.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let counts = appService.proxies.reduce(into: [ProxyHealth: Int]()) { counts, proxy in
                counts[proxy.health, default: 0] += 1
            }
            let showCounts = appService.proxyLoadPhase == .loaded || !appService.proxies.isEmpty
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 8) {
                    healthGrid(showCounts ? counts : nil)
                }
            } else {
                healthGrid(showCounts ? counts : nil)
            }
        }
    }

    private func healthGrid(_ counts: [ProxyHealth: Int]?) -> some View {
        DashboardGrid {
            ForEach(ProxyHealth.allCases) { health in
                DashboardHealthTile(health: health, count: counts.map { $0[health, default: 0] }) {
                    openProxies(.list(health))
                }
            }
        }
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Needs attention").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                if errors.count > 4 {
                    Button("View all") { openProxies(.list(.error)) }
                        .buttonStyle(.borderless)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(errors.prefix(4), id: \.id) { proxy in
                    Button {
                        openProxies(.detail(proxy.id))
                    } label: {
                        HStack(spacing: 14) {
                            ProxyRowView(proxy: proxy)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.forward")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 8)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if proxy.id != errors.prefix(4).last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        }
    }

    private func reload() async {
        let url = instanceURL
        if reportInstance != url {
            reportInstance = url
            report = nil
        }
        guard !url.isEmpty else { return }
        async let proxies: Void = appService.reloadProxies()
        let snapshot = await withCheckedContinuation { continuation in
            ReportsRequest.fetch { _, record in continuation.resume(returning: record) }
        }
        if !Task.isCancelled, instanceURL == url, let snapshot {
            report = snapshot
        }
        await proxies
    }
}
