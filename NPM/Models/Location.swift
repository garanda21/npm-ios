//
//  Location.swift
//  NPM
//
//  Created by Yaser Almasri on 19/08/25.
//

import Foundation

struct Location: Codable {
    var id: Int
    var path: String
    var forward_scheme: String
    var forward_host: String
    var forward_port: Int
    var forward_path: String?
    var advanced_config: String
    var npmplus_enabled: Bool?
    var caching_enabled: Bool?
    var block_exploits: Bool?
    var allow_websocket_upgrade: Bool?
    var npmplus_fancyindex_upstream_compression: Bool?
    var npmplus_noindex: Bool?
    var npmplus_crowdsec_appsec: Bool?
    var npmplus_proxy_request_buffering: Bool?
    var npmplus_proxy_response_buffering: Bool?
    var npmplus_disable_uri_sanitisation: Bool?
    var npmplus_spoof_host_header: Bool?
    var npmplus_upstream_compression: Bool?
    var npmplus_fancyindex: Bool?
    var location_type: String?
    var npmplus_x_frame_options: String?
    var npmplus_auth_request: String?
    var npmplus_auth_request_upstream: String?
    var npmplus_location_config: String?
    var npmplus_access_list_type: String?
    var npmplus_access_list_ids: [Int]?
    var serverID: Int?
    
    enum CodingKeys: String, CodingKey {
        case path
        case forward_scheme
        case forward_host
        case forward_port
        case forward_path
        case advanced_config
        case npmplus_enabled
        case caching_enabled
        case block_exploits
        case allow_websocket_upgrade
        case npmplus_fancyindex_upstream_compression
        case npmplus_noindex
        case npmplus_crowdsec_appsec
        case npmplus_proxy_request_buffering
        case npmplus_proxy_response_buffering
        case npmplus_disable_uri_sanitisation
        case npmplus_spoof_host_header
        case npmplus_upstream_compression
        case npmplus_fancyindex
        case location_type
        case npmplus_x_frame_options
        case npmplus_auth_request
        case npmplus_auth_request_upstream
        case npmplus_location_config
        case npmplus_access_list_type
        case npmplus_access_list_ids
        case serverID = "id"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = Int.random(in: 1000..<9999)
        self.path = try container.decode(String.self, forKey: .path)
        self.forward_scheme = try container.decode(String.self, forKey: .forward_scheme)
        self.forward_host = try container.decode(String.self, forKey: .forward_host)
        self.forward_port = try container.decode(Int.self, forKey: .forward_port)
        self.forward_path = try container.decodeIfPresent(String.self, forKey: .forward_path)
        self.advanced_config = try container.decodeIfPresent(String.self, forKey: .advanced_config) ?? ""
        npmplus_enabled = try container.decodeIfPresent(Bool.self, forKey: .npmplus_enabled)
        caching_enabled = try container.decodeIfPresent(Bool.self, forKey: .caching_enabled)
        block_exploits = try container.decodeIfPresent(Bool.self, forKey: .block_exploits)
        allow_websocket_upgrade = try container.decodeIfPresent(Bool.self, forKey: .allow_websocket_upgrade)
        npmplus_fancyindex_upstream_compression = try container.decodeIfPresent(Bool.self, forKey: .npmplus_fancyindex_upstream_compression)
        npmplus_noindex = try container.decodeIfPresent(Bool.self, forKey: .npmplus_noindex)
        npmplus_crowdsec_appsec = try container.decodeIfPresent(Bool.self, forKey: .npmplus_crowdsec_appsec)
        npmplus_proxy_request_buffering = try container.decodeIfPresent(Bool.self, forKey: .npmplus_proxy_request_buffering)
        npmplus_proxy_response_buffering = try container.decodeIfPresent(Bool.self, forKey: .npmplus_proxy_response_buffering)
        npmplus_disable_uri_sanitisation = try container.decodeIfPresent(Bool.self, forKey: .npmplus_disable_uri_sanitisation)
        npmplus_spoof_host_header = try container.decodeIfPresent(Bool.self, forKey: .npmplus_spoof_host_header)
        npmplus_upstream_compression = try container.decodeIfPresent(Bool.self, forKey: .npmplus_upstream_compression)
        npmplus_fancyindex = try container.decodeIfPresent(Bool.self, forKey: .npmplus_fancyindex)
        location_type = try container.decodeIfPresent(String.self, forKey: .location_type)
        npmplus_x_frame_options = try container.decodeIfPresent(String.self, forKey: .npmplus_x_frame_options)
        npmplus_auth_request = try container.decodeIfPresent(String.self, forKey: .npmplus_auth_request)
        npmplus_auth_request_upstream = try container.decodeIfPresent(String.self, forKey: .npmplus_auth_request_upstream)
        npmplus_location_config = try container.decodeIfPresent(String.self, forKey: .npmplus_location_config)
        npmplus_access_list_type = try container.decodeIfPresent(String.self, forKey: .npmplus_access_list_type)
        npmplus_access_list_ids = try container.decodeIfPresent([Int].self, forKey: .npmplus_access_list_ids)
        serverID = try container.decodeIfPresent(Int.self, forKey: .serverID)
    }
    
    init(path: String, forward_scheme: String, forward_host: String, forward_port: Int, advanced_config: String) {
        self.id = Int.random(in: 1000..<9999)
        self.path = path
        self.forward_scheme = forward_scheme
        self.forward_host = forward_host
        self.forward_port = forward_port
        self.advanced_config = advanced_config
    }
}
