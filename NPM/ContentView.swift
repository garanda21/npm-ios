import SwiftUI

struct ContentView: View {
    private enum Section {
        case dashboard, proxies, redirections, settings
    }

    @EnvironmentObject private var appService: AppService
    @State private var section = Section.dashboard
    @State private var proxyRoute: ProxyRoute?

    var body: some View {
        TabView(selection: $section) {
            Tab("DASHBOARD", systemImage: "house", value: .dashboard) {
                DashboardView(openProxies: openProxies)
            }
            Tab("PROXY", systemImage: "bolt", value: .proxies) {
                ProxiesView(route: $proxyRoute)
            }
            Tab("REDIRECTION", systemImage: "arrow.trianglehead.branch", value: .redirections) {
                RedirectionsView()
            }
            Tab("SETTINGS", systemImage: "gear", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onAppear {
            appService.fetchCerts()
            appService.fetchAccessLists()
        }
    }

    private func openProxies(_ route: ProxyRoute) {
        proxyRoute = route
        section = .proxies
    }
}

#Preview {
    ContentView().environmentObject(AppService())
}
