import Alamofire
import Foundation

final class AuthSessionInterceptor: RequestInterceptor, @unchecked Sendable {
    static let shared = AuthSessionInterceptor()

    private let lock = NSLock()
    private var sessions: [String: SessionState] = [:]

    private struct SessionState {
        var cookie: String
        var expires: Date
        var refreshing = false
        var waiters: [@Sendable (Result<String, any Error>) -> Void] = []
    }

    func register(_ auth: Auth, for url: URL) {
        guard auth.cookieServer != nil,
              let expiration = ISO8601DateFormatter().date(from: auth.expires) else { return }
        lock.lock()
        sessions[Self.origin(for: url)] = SessionState(
            cookie: "\(Auth.cookieName)=\(auth.token)",
            expires: expiration
        )
        lock.unlock()
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        guard let url = urlRequest.url,
              let current = state(for: url),
              urlRequest.value(forHTTPHeaderField: "Cookie") != nil else {
            completion(.success(urlRequest))
            return
        }

        guard current.expires.timeIntervalSinceNow < 5 * 60 else {
            var request = urlRequest
            request.setValue(current.cookie, forHTTPHeaderField: "Cookie")
            completion(.success(request))
            return
        }

        refresh(url: url, completion: { result in
            switch result {
            case .success(let cookie):
                var request = urlRequest
                request.setValue(cookie, forHTTPHeaderField: "Cookie")
                completion(.success(request))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        completion(.doNotRetry)
    }

    private func refresh(
        url: URL,
        completion: @escaping @Sendable (Result<String, any Error>) -> Void
    ) {
        let key = Self.origin(for: url)
        lock.lock()
        guard var current = sessions[key] else {
            lock.unlock()
            completion(.failure(SessionRefreshError.missingSession))
            return
        }
        current.waiters.append(completion)
        guard !current.refreshing else {
            sessions[key] = current
            lock.unlock()
            return
        }
        current.refreshing = true
        sessions[key] = current
        let oldCookie = current.cookie
        lock.unlock()

        guard let refreshURL = Self.refreshURL(for: url) else {
            finishRefresh(key: key, result: .failure(SessionRefreshError.invalidServer))
            return
        }

        AF.request(refreshURL, headers: ["Cookie": oldCookie])
            .validate(statusCode: 200..<300)
            .response { [weak self] response in
                guard let self else { return }
                guard let httpResponse = response.response,
                      let cookie = Auth.cookie(in: httpResponse, named: Auth.cookieName),
                      let expires = Self.expiration(from: response.data) else {
                    self.finishRefresh(
                        key: key,
                        result: .failure(response.error ?? SessionRefreshError.refreshRejected)
                    )
                    return
                }

                let value = "\(Auth.cookieName)=\(cookie.value)"
                self.lock.lock()
                let callbacks = self.sessions[key]?.waiters ?? []
                self.sessions[key] = SessionState(cookie: value, expires: expires)
                self.lock.unlock()
                callbacks.forEach { $0(.success(value)) }
            }
    }

    private func finishRefresh(key: String, result: Result<String, any Error>) {
        lock.lock()
        let callbacks = sessions[key]?.waiters ?? []
        sessions[key]?.refreshing = false
        sessions[key]?.waiters.removeAll()
        lock.unlock()
        callbacks.forEach { $0(result) }
    }

    private func state(for url: URL) -> SessionState? {
        lock.lock()
        defer { lock.unlock() }
        return sessions[Self.origin(for: url)]
    }

    private static func expiration(from data: Data?) -> Date? {
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let expires = object["expires"] else { return nil }
        return ISO8601DateFormatter().date(from: expires)
    }

    private static func refreshURL(for url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "https",
              let range = components.path.range(of: "/api") else { return nil }
        components.path = String(components.path[..<range.lowerBound]) + "/api/tokens"
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func origin(for url: URL) -> String {
        "\(url.scheme ?? "")://\(url.host ?? ""):\(url.port ?? 443)"
    }
}

private enum SessionRefreshError: Error {
    case missingSession
    case invalidServer
    case refreshRejected
}
