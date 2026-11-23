import Alamofire
import Foundation

final class AuthSessionInterceptor: RequestInterceptor, @unchecked Sendable {
    private let lock = NSLock()
    private var refreshedCookies: [String: String] = [:]

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        var request = urlRequest
        guard let url = request.url,
              let refreshedCookie = cookie(for: url),
              request.value(forHTTPHeaderField: "Cookie") != nil else {
            completion(.success(request))
            return
        }
        request.setValue(refreshedCookie, forHTTPHeaderField: "Cookie")
        completion(.success(request))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        guard request.retryCount == 0,
              request.response?.statusCode == 401,
              let url = request.request?.url,
              let cookieHeader = request.request?.value(forHTTPHeaderField: "Cookie"),
              Self.sessionCookie(from: cookieHeader) != nil,
              let refreshURL = Self.refreshURL(for: url) else {
            completion(.doNotRetry)
            return
        }

        AF.request(
            refreshURL,
            headers: ["Cookie": cookieHeader]
        )
        .validate(statusCode: 200..<300)
        .response { [weak self] response in
            guard let self,
                  let httpResponse = response.response,
                  let refreshedCookie = Auth.cookie(in: httpResponse, named: Auth.cookieName) else {
                completion(.doNotRetry)
                return
            }

            let value = "\(Auth.cookieName)=\(refreshedCookie.value)"
            self.store(value, for: url)
            completion(.retry)
        }
    }

    private func store(_ cookie: String, for url: URL) {
        lock.lock()
        refreshedCookies[Self.origin(for: url)] = cookie
        lock.unlock()
    }

    private func cookie(for url: URL) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return refreshedCookies[Self.origin(for: url)]
    }

    private static func sessionCookie(from header: String) -> HTTPCookie? {
        guard let value = header
            .split(separator: ";", maxSplits: 1)
            .first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(Auth.cookieName)=") })?
            .split(separator: "=", maxSplits: 1)
            .last,
              !value.isEmpty else { return nil }
        return HTTPCookie(properties: [
            .name: Auth.cookieName,
            .value: String(value),
            .domain: "cookie.invalid",
            .path: "/",
            .secure: "TRUE"
        ])
    }

    private static func refreshURL(for url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "https",
              components.host != nil else { return nil }
        let path = components.path
        guard path == "/api" || path.hasPrefix("/api/") else { return nil }
        let apiRoot = String(path.prefix(while: { $0 != "?" }))
        guard let apiRange = apiRoot.range(of: "/api") else { return nil }
        components.path = String(apiRoot[..<apiRange.lowerBound]) + "/api/tokens"
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func origin(for url: URL) -> String {
        "\(url.scheme ?? "")://\(url.host ?? ""):\(url.port ?? 443)"
    }
}
