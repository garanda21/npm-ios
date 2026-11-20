//
//  Cert.swift
//  NPM
//
//  Created by Yaser Almasri on 15/08/25.
//

struct Cert: Decodable {
    var id: Int
    var created_on: String
    var modified_on: String
    var owner_user_id: Int
    var provider: String
    var nice_name: String
    var domain_names: [String]
    var expires_on: String?
    var meta: Meta
    
    var proxy_hosts: [Proxy]?
    var redirection_hosts: [Redirection]?
    var dead_hosts: [DeadHost]?
    var streams: [Stream]?

    var inUse: Bool {
        proxy_hosts?.isEmpty == false ||
            redirection_hosts?.isEmpty == false ||
            dead_hosts?.isEmpty == false ||
            streams?.isEmpty == false
    }
}
