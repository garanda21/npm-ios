//
//  ProxyAccessListView.swift
//  NPM
//
//  Created by Yaser Almasri on 18/08/25.
//

import SwiftUI

struct ProxyAccessListView: View {
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss

    var proxy: Proxy
    
    @State private var selectedAccessLists: [Int] = []
    
    var body: some View {
        List {
            Button {
                self.selectedAccessLists = []
            } label: {
                HStack {
                    Text("PUBLICLY_ACCESSIBLE")
                    Spacer()
                    if self.selectedAccessLists.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .tint(.primary)
            
            ForEach(self.appService.accessLists, id: \.id) { accessList in
                Button {
                    if proxy.npmplus_access_list_ids == nil {
                        selectedAccessLists = [accessList.id]
                    } else if selectedAccessLists.contains(accessList.id) {
                        selectedAccessLists.removeAll { $0 == accessList.id }
                    } else {
                        selectedAccessLists.append(accessList.id)
                    }
                } label: {
                    HStack {
                        Text(accessList.name)
                        Spacer()
                        if self.selectedAccessLists.contains(accessList.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }//hstack
                }//button
                .tint(.primary)
            }//Loop
        }//List
        .onAppear {
            self.appService.fetchAccessLists()
            self.selectedAccessLists = proxy.accessListIDs
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.save()
                } label: {
                    Text("SAVE")
                }
            }
        }
    }
    
    private func save() {
        ProxiesRequest.updateAccessList(id: self.proxy.id, accessListIDs: selectedAccessLists, usesMultipleLists: proxy.npmplus_access_list_ids != nil) { success in
            if success {
                self.appService.fetchProxies()
                self.dismiss()
            }
        }
    }
}

#Preview {
    ProxyAccessListView(proxy: Proxy.fake())
}
