import SwiftUI

struct ProxyListPlaceholder: View {
    let instanceConfigured: Bool
    let phase: ProxyLoadPhase
    let filtered: Bool
    let retry: () -> Void
    let reset: () -> Void

    var body: some View {
        if !instanceConfigured {
            ContentUnavailableView("Connect an instance", systemImage: "server.rack", description: Text("Add your server in Settings."))
        } else if phase == .idle || phase == .loading {
            ProgressView("Loading proxies…")
        } else if phase == .failed {
            ContentUnavailableView {
                Label("Couldn't load proxies", systemImage: "wifi.exclamationmark")
            } actions: {
                Button("Try Again", action: retry)
            }
        } else if filtered {
            ContentUnavailableView {
                Label("No matching proxies", systemImage: "magnifyingglass")
            } actions: {
                Button("Clear Filters", action: reset)
            }
        } else {
            ContentUnavailableView("No proxy hosts", systemImage: "bolt.horizontal.circle", description: Text("Use Add Proxy to create one."))
        }
    }
}
