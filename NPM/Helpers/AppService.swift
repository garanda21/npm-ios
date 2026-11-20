//
//  AppService.swift
//  NPM
//
//  Created by Yaser Almasri on 13/08/25.
//

import SwiftUI

class AppService: ObservableObject {
    
    public static var shared = AppService()
    
    @AppStorage("npm_server_url") private var instanceURL: String = ""
    
    @Published var plugins: [String: Plugin] = [:]
    @Published var certs: [Cert] = []
    @Published var proxies: [Proxy] = []
    @Published private(set) var proxyLoadPhase: ProxyLoadPhase = .idle
    private var proxyRequestID = UUID()
    private var proxyInstanceURL: String?
    private var proxyWaiters: [CheckedContinuation<Void, Never>] = []
    @Published var accessLists: [AccessList] = []
    @Published var redirections: [Redirection] = []
    @Published var streams: [Stream] = []
    @Published var deadHosts: [DeadHost] = []
    
    public func fetchCerts() {
        CertsRequest.fetch { success, records in
            self.certs = records
        }
    }
    
    @MainActor
    func fetchProxies() {
        loadProxies(force: true)
    }

    @MainActor
    func reloadProxies() async {
        await withCheckedContinuation { continuation in
            proxyWaiters.append(continuation)
            loadProxies(force: false)
        }
    }

    @MainActor
    private func loadProxies(force: Bool) {
        let url = instanceURL
        if url != proxyInstanceURL {
            proxyInstanceURL = url
            proxies = []
            proxyLoadPhase = .idle
        }
        guard !url.isEmpty else {
            finishProxyReload()
            return
        }
        guard force || proxyLoadPhase != .loading else { return }
        proxyLoadPhase = .loading
        let requestID = UUID()
        proxyRequestID = requestID
        ProxiesRequest.fetch { success, records in
            guard self.proxyRequestID == requestID else { return }
            if self.instanceURL == url {
                if success { self.proxies = records }
                self.proxyLoadPhase = success ? .loaded : .failed
            } else {
                self.proxies = []
                self.proxyLoadPhase = .idle
            }
            self.finishProxyReload()
        }
    }

    private func finishProxyReload() {
        let waiters = proxyWaiters
        proxyWaiters.removeAll()
        for waiter in waiters { waiter.resume() }
    }

    public func fetchAccessLists() {
        AccessListsRequest.fetch { success, records in
            self.accessLists = records
        }
    }
    
    public func fetchRedirections() {
        RedirectionsRequest.fetch { success, records in
            self.redirections = records
        }
    }
    
    public func fetchStreams() {
        StreamsRequest.fetch { success, records in
            self.streams = records
        }
    }
    
    public func fetchDeadHosts() {
        DeadHostsRequest.fetch { success, records in
            self.deadHosts = records
        }
    }
    
    public func setPlugins() {
        if let plugins = loadPlugins(from: "certbot-dns-plugins.json") {
            self.plugins = plugins
        } else {
            print("Failed to load plugins.")
        }
    }
}
