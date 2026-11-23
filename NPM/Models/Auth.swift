import Alamofire
import Foundation

struct Auth: Codable {
    static let cookieName = "__Host-Http-token"
    static let cookieSession = Session(
        configuration: {
            let configuration = URLSessionConfiguration.af.ephemeral
            configuration.httpShouldSetCookies = false
            configuration.httpCookieStorage = nil
            return configuration
        }(),
        interceptor: AuthSessionInterceptor.shared,
        redirectHandler: Redirector(behavior: .doNotFollow)
    )

    var token: String
    var expires: String
    var cookieServer: String? = nil

    var session: Session {
        cookieServer == nil ? AF : Self.cookieSession
    }

    func headers(for url: URL) -> HTTPHeaders {
        guard let cookieServer else {
            return ["Authorization": "Bearer \(token)"]
        }
        guard let server = URL(string: cookieServer),
              url.scheme == "https",
              url.host == server.host,
              url.port == server.port else {
            return [:]
        }
        AuthSessionInterceptor.shared.register(self, for: url)
        return ["Cookie": "\(Self.cookieName)=\(token)"]
    }

    static func cookie(in response: HTTPURLResponse, named name: String) -> HTTPCookie? {
        guard let url = response.url, url.scheme == "https",
              let value = response.value(forHTTPHeaderField: "Set-Cookie") else { return nil }
        return HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": value], for: url)
            .first { $0.name == name && $0.isSecure && $0.path == "/" && !$0.value.isEmpty }
    }
}
