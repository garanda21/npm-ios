import Alamofire
import Foundation

enum AuthLoginResult {
    case success(Auth)
    case verificationRequired(AuthChallenge)
    case failure
}

enum AuthChallenge {
    case twoFactor(String)
    case totpCookie(String)
}

enum AuthRequest {
    private struct TokenResponse: Decodable {
        var token: String?
        var expires: String?
        var challenge_token: String?
        var requiresTotp: Bool?
    }

    static func login(
        server: URL,
        username: String,
        password: String,
        completion: @escaping (AuthLoginResult) -> Void
    ) {
        let url = server.appendingPathComponent("api/tokens")
        Auth.cookieSession.request(
            url, method: .post,
            parameters: ["identity": username, "secret": password],
            encoding: JSONEncoding.default
        )
        .validate(statusCode: 200..<300)
        .responseDecodable(of: TokenResponse.self) { response in
            guard let body = response.value, let http = response.response else {
                completion(.failure)
                return
            }
            if let challenge = body.challenge_token {
                completion(server.scheme == "https" ? .verificationRequired(.twoFactor(challenge)) : .failure)
            } else if body.requiresTotp == true,
                      let cookie = Auth.cookie(in: http, named: "__Host-Http-challenge_token") {
                completion(.verificationRequired(.totpCookie(cookie.value)))
            } else if let auth = cookieAuth(server: server, body: body, response: http) {
                completion(.success(auth))
            } else if let token = body.token, let expires = body.expires {
                let initial = Auth(token: token, expires: expires)
                AF.request(url, parameters: ["expiry": "5y"], headers: initial.headers(for: url))
                    .validate(statusCode: 200..<300)
                    .responseDecodable(of: Auth.self) { refreshed in
                        completion(.success(refreshed.value ?? initial))
                    }
            } else {
                completion(.failure)
            }
        }
    }

    static func verify(
        server: URL,
        challenge: AuthChallenge,
        code: String,
        completion: @escaping (AuthLoginResult) -> Void
    ) {
        guard server.scheme == "https" else {
            completion(.failure)
            return
        }
        let path: String
        var parameters = ["code": code]
        var headers = HTTPHeaders()
        switch challenge {
        case .twoFactor(let token):
            path = "api/tokens/2fa"
            parameters["challenge_token"] = token
        case .totpCookie(let token):
            path = "api/tokens/totp"
            headers.add(name: "Cookie", value: "__Host-Http-challenge_token=\(token)")
        }
        Auth.cookieSession.request(
            server.appendingPathComponent(path), method: .post,
            parameters: parameters, encoding: JSONEncoding.default, headers: headers
        )
        .validate(statusCode: 200..<300)
        .responseDecodable(of: TokenResponse.self) { response in
            guard let body = response.value, let http = response.response,
                  let auth = cookieAuth(server: server, body: body, response: http) else {
                completion(.failure)
                return
            }
            completion(.success(auth))
        }
    }

    private static func cookieAuth(server: URL, body: TokenResponse, response: HTTPURLResponse) -> Auth? {
        guard let expires = body.expires,
              let cookie = Auth.cookie(in: response, named: Auth.cookieName) else { return nil }
        return Auth(token: cookie.value, expires: expires, cookieServer: server.absoluteString)
    }
}
