//
//  StreamsRequest.swift
//  NPM
//
//  Created by Yaser Almasri on 13/09/25.
//

import SwiftUI
import Alamofire

class StreamsRequest {
    public static func fetch(
        completionHandler: @escaping (_ success: Bool, _ records: [Stream]) -> Void
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
        
        let url = URL(string: "\(baseUrl)/api/nginx/streams")!
        let headers = auth.headers(for: url)
        auth.session.request(url, headers: headers)
            .responseDecodable(of: [Stream].self) { response in
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
        incomingPort: String,
        forwardHost: String,
        forwardPort: String,
        tcpForwarding: Bool,
        udpForwarding: Bool,
        certificateId: Int,
        completionHandler: @escaping (_ success: Bool, _ record: Stream?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else
        {
            completionHandler(false, nil)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let ports: (incoming: Any, forwarding: Any)
        if auth.cookieServer != nil {
            ports = (incomingPort, forwardPort)
        } else if let incoming = Int(incomingPort), let forwarding = Int(forwardPort) {
            ports = (incoming, forwarding)
        } else {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/api/nginx/streams")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        auth.session.request(url, method: .post, parameters: [
            "incoming_port": ports.incoming,
            "forwarding_host": forwardHost,
            "forwarding_port": ports.forwarding,
            "tcp_forwarding": tcpForwarding,
            "udp_forwarding": udpForwarding,
            "certificate_id": certificateId
        ], encoding: encoding, headers: headers)
            .responseDecodable(of: Stream.self) { response in
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
        incomingPort: String,
        forwardHost: String,
        forwardPort: String,
        tcpForwarding: Bool,
        udpForwarding: Bool,
        certificateId: Int,
        completionHandler: @escaping (_ success: Bool, _ record: Stream?) -> Void
    ) {
        let userDefaults = UserDefaults.standard
        guard let baseUrl = userDefaults.string(forKey: "npm_server_url"),
              let auth_data = userDefaults.data(forKey: "npm_auth") else
        {
            completionHandler(false, nil)
            return
        }
        guard let auth = try? JSONDecoder().decode(Auth.self, from: auth_data) else {
            return
        }
        
        let ports: (incoming: Any, forwarding: Any)
        if auth.cookieServer != nil {
            ports = (incomingPort, forwardPort)
        } else if let incoming = Int(incomingPort), let forwarding = Int(forwardPort) {
            ports = (incoming, forwarding)
        } else {
            completionHandler(false, nil)
            return
        }

        let url = URL(string: "\(baseUrl)/api/nginx/streams/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        auth.session.request(url, method: .put, parameters: [
            "incoming_port": ports.incoming,
            "forwarding_host": forwardHost,
            "forwarding_port": ports.forwarding,
            "tcp_forwarding": tcpForwarding,
            "udp_forwarding": udpForwarding,
            "certificate_id": certificateId
        ], encoding: encoding, headers: headers)
            .responseDecodable(of: Stream.self) { response in
                switch response.result {
                case .success(let record):
                    completionHandler(true, record)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false, nil)
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
        
        let url = URL(string: "\(baseUrl)/api/nginx/streams/\(id)")!
        let headers = auth.headers(for: url)
        let encoding = JSONEncoding.default
        auth.session.request(url,method: .delete, encoding: encoding, headers: headers)
            .responseDecodable(of: Bool.self) { response in
                switch response.result {
                case .success(let success):
                    completionHandler(success)
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(false)
                }
            }
    }
}
