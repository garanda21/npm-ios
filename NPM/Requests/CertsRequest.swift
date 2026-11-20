//
//  CertsRequest.swift
//  NPM
//
//  Created by Yaser Almasri on 15/08/25.
//

import SwiftUI
import Alamofire

class CertsRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ records: [Cert]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else
        {
            completionHandler(false, [])
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let streamExpansion = auth.cookieServer == nil ? "" : ",streams"
        let url = URL(string: "\(baseUrl)/api/nginx/certificates?expand=proxy_hosts,dead_hosts,redirection_hosts\(streamExpansion)")!
        let headers = auth.headers(for: url)
        auth.session.request(url, headers: headers)
            .responseDecodable(of: [Cert].self) { response in
                switch response.result {
                case .success(let records):
                    completionHandler(true, records)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, [])
                }
            }
    }
    
    public static func create(
        domains: [String],
        dnsChallenge: Bool,
        dnsProvider: String,
        dnsCredentials: String,
        propagationSeconds: Int?,
        completionHandler: @escaping (_ success: Bool, _ record: Cert?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false, nil)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else { return }

        let url = URL(string: "\(baseUrl)/api/nginx/certificates")!
        let headers = auth.headers(for: url)
        var meta: [String: Any] = ["letsencrypt_agree": true]
        if dnsChallenge {
            meta["dns_challenge"] = true
            meta["dns_provider"] = dnsProvider
            meta["dns_provider_credentials"] = dnsCredentials
            if let secs = propagationSeconds {
                meta["propagation_seconds"] = secs
            }
        }
        let params: [String: Any] = ["provider": "letsencrypt", "domain_names": domains, "meta": meta]
        auth.session.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: Cert.self) { response in
                switch response.result {
                case .success(let record):
                    completionHandler(true, record)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, nil)
                }
            }
    }
}
