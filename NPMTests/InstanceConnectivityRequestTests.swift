import XCTest
@testable import NPM

final class InstanceConnectivityRequestTests: XCTestCase {
    func testSuccessfulResponseIsConnected() {
        XCTAssertEqual(
            InstanceConnectivityRequest.status(statusCode: 200, hasTransportError: false),
            .connected
        )
    }

    func testUnauthorizedResponseIsAuthenticationFailure() {
        XCTAssertEqual(
            InstanceConnectivityRequest.status(statusCode: 401, hasTransportError: false),
            .authenticationFailed
        )
    }

    func testForbiddenResponseIsAuthenticationFailure() {
        XCTAssertEqual(
            InstanceConnectivityRequest.status(statusCode: 403, hasTransportError: false),
            .authenticationFailed
        )
    }

    func testServerErrorIsUnavailable() {
        XCTAssertEqual(
            InstanceConnectivityRequest.status(statusCode: 500, hasTransportError: false),
            .serverUnavailable
        )
    }

    func testTransportErrorIsUnavailable() {
        XCTAssertEqual(
            InstanceConnectivityRequest.status(statusCode: nil, hasTransportError: true),
            .serverUnavailable
        )
    }

    func testConnectedStatusIsNotRetryable() {
        XCTAssertFalse(InstanceConnectivityStatus.connected.isRetryable)
    }

    func testAuthenticationFailureIsRetryable() {
        XCTAssertTrue(InstanceConnectivityStatus.authenticationFailed.isRetryable)
    }

    func testServerUnavailableIsRetryable() {
        XCTAssertTrue(InstanceConnectivityStatus.serverUnavailable.isRetryable)
    }

    func testMissingStoredAuthenticationReturnsAuthenticationFailure() {
        let suiteName = "\(Self.self).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set("https://npm.example.com", forKey: "npm_server_url")

        let expectation = expectation(description: "completion")
        InstanceConnectivityRequest.check(userDefaults: defaults) { status in
            XCTAssertEqual(status, .authenticationFailed)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testMissingStoredAuthenticationCompletesOnMainThread() {
        let suiteName = "\(Self.self).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set("https://npm.example.com", forKey: "npm_server_url")

        let expectation = expectation(description: "completion")
        DispatchQueue.global().async {
            InstanceConnectivityRequest.check(userDefaults: defaults) { _ in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testRequestUsesAuthenticatedCurrentUserEndpoint() throws {
        let request = try XCTUnwrap(
            InstanceConnectivityRequest.request(
                baseURL: "https://npm.example.com",
                token: "test-token"
            )
        )

        XCTAssertEqual(request.url?.path, "/api/users/me")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token"
        )
    }

    func testRequestHandlesTrailingSlashInBaseURL() throws {
        let request = try XCTUnwrap(
            InstanceConnectivityRequest.request(
                baseURL: "https://npm.example.com/",
                token: "test-token"
            )
        )

        XCTAssertEqual(request.url?.absoluteString, "https://npm.example.com/api/users/me")
    }
}

extension InstanceConnectivityRequestTests {
    func testNPMPlusCookieIsOnlySentToConfiguredHTTPSOrigin() throws {
        let auth = Auth(token: "s%3Asigned-cookie", expires: "", cookieServer: "https://npm.example.com:81")
        let matching = try XCTUnwrap(InstanceConnectivityRequest.request(
            baseURL: "https://npm.example.com:81", auth: auth
        ))
        XCTAssertEqual(matching.value(forHTTPHeaderField: "Cookie"), "__Host-Http-token=s%3Asigned-cookie")
        XCTAssertNil(matching.value(forHTTPHeaderField: "Authorization"))

        for server in ["http://npm.example.com:81", "https://npm.example.com", "https://different.example.com:81"] {
            let request = try XCTUnwrap(InstanceConnectivityRequest.request(baseURL: server, auth: auth))
            XCTAssertNil(request.value(forHTTPHeaderField: "Cookie"))
        }
    }

    func testLegacyStoredTokenStillDecodes() throws {
        let data = Data(#"{"token":"legacy","expires":"2030-01-01T00:00:00Z"}"#.utf8)
        let auth = try JSONDecoder().decode(Auth.self, from: data)
        XCTAssertEqual(auth.token, "legacy")
        XCTAssertNil(auth.cookieServer)
    }

    func testStreamPortsDecodeBothFormats() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(StreamPort.self, from: Data("443".utf8)).wrappedValue, "443")
        XCTAssertEqual(try decoder.decode(StreamPort.self, from: Data(#""8000-8009""#.utf8)).wrappedValue, "8000-8009")
        XCTAssertEqual(try decoder.decode(StreamPort.self, from: Data("null".utf8)).wrappedValue, "")
    }
}
