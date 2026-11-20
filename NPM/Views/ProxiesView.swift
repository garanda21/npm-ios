import SwiftUI

struct ProxiesView: View {
    @EnvironmentObject private var appService: AppService
    @AppStorage("npm_server_url") private var instanceURL = ""

    @Binding var route: ProxyRoute?
    @State private var query = ""
    @State private var filter: ProxyHealth?
    @State private var selection: Int?
    @State private var compactColumn = NavigationSplitViewColumn.sidebar
    @State private var isCreating = false

    private var results: [Proxy] {
        appService.proxies.filter { proxy in
            (filter == nil || proxy.health == filter) && proxy.matchesSearch(query)
        }
    }

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            List(selection: $selection) {
                if !results.isEmpty && appService.proxyLoadPhase == .failed {
                    Label("Couldn't refresh proxies. Pull to retry.", systemImage: "wifi.exclamationmark")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let filter {
                    Section {
                        ForEach(results, id: \.id, content: proxyLink)
                    } header: {
                        ProxyHealthLabel(health: filter)
                    }
                } else {
                    ForEach(results, id: \.id, content: proxyLink)
                }
            }
            .overlay {
                if results.isEmpty {
                    ProxyListPlaceholder(
                        instanceConfigured: !instanceURL.isEmpty,
                        phase: appService.proxyLoadPhase,
                        filtered: filter != nil || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        retry: appService.fetchProxies,
                        reset: resetFilters
                    )
                }
            }
            .navigationTitle("PROXY_HOSTS")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search domains or upstreams")
            .refreshable { await appService.reloadProxies() }
            .navigationSplitViewColumnWidth(min: 290, ideal: 360)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Picker("Proxy status", selection: $filter) {
                            Text("All statuses").tag(nil as ProxyHealth?)
                            ForEach(ProxyHealth.allCases) { health in
                                Label(String(localized: health.title), systemImage: health.symbol)
                                    .tag(Optional(health))
                            }
                        }
                    } label: {
                        Label("Filter proxies", systemImage: filter == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    }
                    Button("Add proxy", systemImage: "plus") { isCreating = true }
                        .disabled(instanceURL.isEmpty)
                }
            }
        } detail: {
            NavigationStack {
                if let proxy = appService.proxies.first(where: { $0.id == selection }) {
                    ProxyView(proxy: proxy) {
                        selection = nil
                        compactColumn = .sidebar
                    }
                        .id(proxy.id)
                } else {
                    ContentUnavailableView("Select a proxy", systemImage: "bolt.horizontal.circle")
                }
            }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack {
                ProxiesCreateView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel", role: .cancel) { isCreating = false }
                        }
                    }
            }
        }
        .task(id: instanceURL) { await appService.reloadProxies() }
        .onChange(of: route, initial: true) { _, route in
            if let route { apply(route) }
        }
        .onChange(of: instanceURL) { _, _ in
            selection = nil
            compactColumn = .sidebar
        }
    }

    private func proxyLink(_ proxy: Proxy) -> some View {
        NavigationLink(value: proxy.id) {
            ProxyRowView(proxy: proxy)
        }
    }

    private func apply(_ route: ProxyRoute) {
        resetFilters()
        switch route {
        case .list(let health):
            filter = health
            selection = nil
            compactColumn = .sidebar
        case .detail(let id):
            selection = id
            compactColumn = .detail
        }
        self.route = nil
    }

    private func resetFilters() {
        query = ""
        filter = nil
    }
}
