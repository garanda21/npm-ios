//
//  ProxiesRequest.swift
//  NPM
//
//  Created by Yaser Almasri on 14/08/25.
//

import SwiftUI
import Alamofire

class ProxiesRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ records: [Proxy]) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else
        {
            completionHandler(false, [])
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            completionHandler(false, [])
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts")!
        let headers = auth.headers(for: url)
        auth.session.request(url, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: [Proxy].self) { response in
                switch response.result {
                case .success(let records):
                    completionHandler(true, records)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, [])
                }
            }
    }
    
    public static func toggle(
        id: Int,
        enabled: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        let params: [String: Any] = [
            "enabled": enabled
        ]
        auth.session.request(url, method: .put, parameters: params, encoding: encoding, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func create(
        scheme: String,
        host: String,
        port: Int,
        domains: [String],
        completionHandler: @escaping (_ success: Bool, _ record: Proxy?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false, nil)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        let params: [String: Any] = [
            "domain_names": domains,
            "forward_scheme": scheme,
            "forward_host": host,
            "forward_port": port
        ]
        auth.session.request(url,method: .post, parameters: params, encoding: encoding, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(let record):
                    completionHandler(true, record)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func update(
        id: Int,
        scheme: String,
        host: String,
        port: Int,
        domains: [String],
        completionHandler: @escaping (_ success: Bool, _ record: Proxy?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false, nil)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        let params: [String: Any] = [
            "domain_names": domains,
            "forward_scheme": scheme,
            "forward_host": host,
            "forward_port": port
        ]
        auth.session.request(url,method: .put, parameters: params, encoding: encoding, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(let record):
                    completionHandler(true, record)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, nil)
                }
            }
    }
    
    public static func updateSSL(
        id: Int,
        cert_id: Int,
        forceSSL: Bool,
        httpSupport: Bool,
        hsts: Bool,
        hstsSubdomains: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        let params: [String: Any] = [
            "certificate_id": cert_id,
            "ssl_forced": forceSSL,
            "hsts_enabled": hsts,
            "hsts_subdomains": hstsSubdomains,
            "http2_support": httpSupport
        ]
        auth.session.request(url, method: .put, parameters: params, encoding: encoding, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func updateAccessList(
        id: Int,
        accessListIDs: [Int],
        usesMultipleLists: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        let params: [String: Any]
        if usesMultipleLists {
            params = [
                "npmplus_access_list_ids": accessListIDs,
                "npmplus_access_list_type": accessListIDs.isEmpty ? "public" : "custom"
            ]
        } else {
            params = ["access_list_id": accessListIDs.first ?? 0]
        }
        auth.session.request(url, method: .put, parameters: params, encoding: encoding, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func updateLocations(
        id: Int,
        locations: [Location],
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        var locations = locations
        if auth.cookieServer != nil {
            for index in locations.indices {
                if locations[index].npmplus_access_list_ids == nil {
                    locations[index].npmplus_access_list_ids = []
                }
                if locations[index].npmplus_access_list_type == nil {
                    locations[index].npmplus_access_list_type = "global"
                }
            }
        }
        auth.session.request(url, method: .put, parameters: ["locations": locations], encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func delete(
        id: Int,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        auth.session.request(url, method: .delete, headers: headers)
            .response { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func updateCacheAssets(
        id: Int,
        cacheAssets: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        auth.session.request(url, method: .put, parameters: ["caching_enabled": cacheAssets], encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func updateBlockCommonExploits(
        id: Int,
        blockCommonExploits: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        auth.session.request(url, method: .put, parameters: ["block_exploits": blockCommonExploits], encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
    
    public static func updateWebsocketsSupport(
        id: Int,
        websocketsSupport: Bool,
        completionHandler: @escaping (_ success: Bool) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else {
            completionHandler(false)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let url = URL(string: "\(baseUrl)/api/nginx/proxy-hosts/\(id)")!
        let headers = auth.headers(for: url)
        auth.session.request(url, method: .put, parameters: ["allow_websocket_upgrade": websocketsSupport], encoder: JSONParameterEncoder.default, headers: headers)
            .responseDecodable(of: Proxy.self) { response in
                switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
}
