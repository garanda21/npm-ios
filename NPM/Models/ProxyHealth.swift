import Foundation

enum ProxyHealth: String, CaseIterable, Identifiable {
    case active, error, disabled, unknown

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .active: "Active"
        case .error: "Errors"
        case .disabled: "Disabled"
        case .unknown: "Unreported"
        }
    }

    var symbol: String {
        switch self {
        case .active: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        case .disabled: "pause.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }
}

extension Proxy {
    var health: ProxyHealth {
        if !enabled { return .disabled }
        if meta.nginx_online == false || !(meta.nginx_err ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .error
        }
        return meta.nginx_online == true ? .active : .unknown
    }

    var displayName: String {
        domain_names.first ?? String(localized: "No domain")
    }

    func matchesSearch(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ||
            domain_names.contains { $0.localizedStandardContains(query) } ||
            host.localizedStandardContains(query)
    }
}
