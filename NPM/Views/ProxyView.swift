//
//  ProxyView.swift
//  NPM
//
//  Created by Yaser Almasri on 17/08/25.
//

import SwiftUI

struct ProxyView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var proxy: Proxy
    var onDelete: (() -> Void)? = nil
    
    @State private var cacheAssets: Bool = false
    @State private var blockCommonExploits: Bool = false
    @State private var websocketsSupport: Bool = false
    @State private var isShowingDeleteConfirmation: Bool = false
    
    var accessList: String {
        let names = proxy.accessListIDs.map { id in
            appService.accessLists.first { $0.id == id }?.name ?? "#\(id)"
        }
        return names.isEmpty ? "PUBLICLY_ACCESSIBLE" : names.joined(separator: ", ")
    }
    
    var cert: Cert? {
        return self.appService.certs.first { c in
            c.id == self.proxy.certificate_id
        }
    }
    
    var body: some View {
        List {
            Section {
                ProxyHealthLabel(health: proxy.health)
                if proxy.health == .error, let message = proxy.meta.nginx_err, !message.isEmpty {
                    Text(message)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
            }
            hostSection
            
            Section {
                HStack {
                    Text("HOST")
                    Spacer()
                    Text(self.proxy.host)
                }
            }
            
            configSection
            
            authConfigSection
            
            deleteButton
        }
        .onAppear {
            self.cacheAssets = self.proxy.caching_enabled
            self.blockCommonExploits = self.proxy.block_exploits
            self.websocketsSupport = self.proxy.allow_websocket_upgrade
        }
        .navigationTitle(proxy.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    NavigationLink(destination: {
                        ProxyEditView(proxy: self.proxy)
                            .environmentObject(self.appService)
                    }, label: {
                        Image(systemName: "square.and.pencil")
                    })
                    
                    Button {
                        ProxiesRequest.toggle(id: self.proxy.id, enabled: !self.proxy.enabled) { success in
                            if success {
                                self.appService.fetchProxies()
                            }
                        }
                    } label: {
                        Image(systemName: self.proxy.enabled ? "power.circle.fill" : "power.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }

                }
            }
        }
    }//body
    
    private func delete() {
        ProxiesRequest.delete(id: self.proxy.id) { success in
            if success {
                self.appService.fetchProxies()
                if let onDelete {
                    onDelete()
                } else {
                    dismiss()
                }
            }
        }
    }
}

extension ProxyView {
    var hostSection: some View {
        Section(header: Text("DOMAIN_NAMES")) {
            ForEach(self.proxy.domain_names, id: \.self) { domain in
                Link(domain, destination: fullDomain(from: domain))
            }
        }//Section
        .textCase(nil)
    }//hostSection
    
    var configSection: some View {
        Section {
            Toggle("CACHE_ASSETS", isOn: $cacheAssets)
                .onChange(of: cacheAssets) { oldVal, newVal in
                    ProxiesRequest.updateCacheAssets(id: self.proxy.id, cacheAssets: self.cacheAssets) { success in
                        if success { self.appService.fetchProxies() }
                    }
                }
            Toggle("BLOCK_COMMON_EXPLOITS", isOn: $blockCommonExploits)
                .onChange(of: blockCommonExploits) { oldVal, newVal in
                    ProxiesRequest.updateBlockCommonExploits(id: self.proxy.id, blockCommonExploits: self.blockCommonExploits) { success in
                        if success { self.appService.fetchProxies() }
                    }
                }
            Toggle("WEBSOCKETS_SUPPORT", isOn: $websocketsSupport)
                .onChange(of: websocketsSupport) { oldVal, newVal in
                    ProxiesRequest.updateWebsocketsSupport(id: self.proxy.id, websocketsSupport: self.websocketsSupport) { success in
                        if success { self.appService.fetchProxies() }
                    }
                }
        }//section
    }
    
    var authConfigSection: some View {
        Section {
            NavigationLink {
                ProxyAccessListView(proxy: self.proxy)
                    .environmentObject(AppService.shared)
            } label: {
                HStack {
                    Text("ACCESS_LIST")
                    Spacer()
                    Text(LocalizedStringResource(stringLiteral: accessList))
                        .foregroundStyle(.secondary)
                }//HStack
            }//HStack
            
            NavigationLink {
                ProxyLocationsView(proxy: self.proxy)
                    .environmentObject(AppService.shared)
            } label: {
                Text("LOCATIONS")
            }//HStack
            
            NavigationLink {
                SSLPickerView(host: self.proxy)
                    .environmentObject(AppService.shared)
            } label: {
                HStack {
                    Text("SSL")
                    Spacer()
                    if cert != nil {
                        Text(cert!.nice_name)
                            .foregroundStyle(.secondary)
                    }
                }
            }//HStack
        }//section
    }
    
    var deleteButton: some View {
        Section {
            HStack {
                Spacer()
                Button("DELETE") {
                    self.isShowingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
                .confirmationDialog("DELETE", isPresented: $isShowingDeleteConfirmation) {
                    Button("DELETE", role: .destructive) {
                        self.delete()
                    }
                    Button("CANCEL", role: .cancel) {}
                }
                Spacer()
            }//hstack
        }//section
    }
    
    private func fullDomain(from domain: String) -> URL {
        let scheme = self.proxy.certificate_id == 0 ? "http" : "https"
        return URL(string: "\(scheme)://\(domain)")!
    }
}

#Preview {
    ProxyView(proxy: Proxy.fake())
        .environmentObject(AppService.shared)
}
