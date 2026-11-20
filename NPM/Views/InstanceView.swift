//
//  InstanceView.swift
//  NPM
//
//  Created by Yaser Almasri on 14/08/25.
//

import SwiftUI
import Network

struct InstanceView: View {
    
    @AppStorage("npm_server_url") var npmServerUrl: String = ""
    @AppStorage("npm_username") var npmUsername: String = ""
    @AppStorage("npm_password") var npmPassword: String = ""
    
    @EnvironmentObject var appService: AppService
    @Environment(\.dismiss) var dismiss
    
    @State private var serverUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var challenge: AuthChallenge?
    
    @State private var connectionError: Bool = false
    @State private var isInvalidURL: Bool = false
    @State private var isLoading: Bool = false

    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("SERVER_URL")
                    TextField("SERVER_URL", text: $serverUrl)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("USERNAME")
                    TextField("USERNAME", text: $username)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("PASSWORD")
                    SecureField("PASSWORD", text: $password)
                        .multilineTextAlignment(.trailing)
                }
                
                if challenge != nil {
                    TextField("Verification code", text: $verificationCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textContentType(.oneTimeCode)
                }

                if connectionError == true {
                    Text("ERROR_CONNECTING_TO_SERVER")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }
                
                if isInvalidURL {
                    Text("INVALID_SERVER_URL")
                        .foregroundStyle(.red)
                        .font(.system(size: 14))
                }

            }
            .disabled(isLoading)
        }
        .onChange(of: serverUrl) { _, _ in resetChallenge() }
        .onChange(of: username) { _, _ in resetChallenge() }
        .onChange(of: password) { _, _ in resetChallenge() }
        .onAppear {
            self.serverUrl = self.npmServerUrl
            self.username = self.npmUsername
            self.password = self.npmPassword
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if self.isLoading == false {
                        self.save()
                    }
                } label: {
                    Text("SAVE")
                }
            }
        }
    }
    
    private func save() {
        self.isInvalidURL = false
        self.connectionError = false
        
        if self.serverUrl.isEmpty || self.username.isEmpty || self.password.isEmpty {
            return
        }
        
        let normalizedURL = serverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let components = URLComponents(string: normalizedURL),
              let url = components.url,
              let scheme = components.scheme, ["https", "http"].contains(scheme),
              components.host?.isEmpty == false,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            self.isInvalidURL = true
            return
        }

        let completion: (AuthLoginResult) -> Void = { result in
            self.isLoading = false
            switch result {
            case .success(let auth):
                guard let encoded = try? JSONEncoder().encode(auth) else {
                    self.connectionError = true
                    return
                }
                UserDefaults.standard.set(encoded, forKey: "npm_auth")
                self.npmUsername = self.username
                self.npmServerUrl = url.absoluteString
                self.npmPassword = ""
                self.appService.fetchCerts()
                self.appService.fetchAccessLists()
                self.dismiss()
            case .verificationRequired(let challenge):
                self.challenge = challenge
            case .failure:
                self.connectionError = true
            }
        }

        if let challenge {
            let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !code.isEmpty else { return }
            self.isLoading = true
            AuthRequest.verify(server: url, challenge: challenge, code: code, completion: completion)
        } else {
            self.isLoading = true
            AuthRequest.login(server: url, username: username, password: password, completion: completion)
        }
    }

    private func resetChallenge() {
        challenge = nil
        verificationCode = ""
    }

}

#Preview {
    InstanceView()
}
