import XCTest
@testable import NPM

final class ProxyHealthTests: XCTestCase {
    func testHealthDistinguishesActiveErrorDisabledAndUnreported() {
        var proxy = Proxy.fake()
        XCTAssertEqual(proxy.health, .active)

        proxy.meta.nginx_online = nil
        XCTAssertEqual(proxy.health, .unknown)

        proxy.meta.nginx_online = false
        XCTAssertEqual(proxy.health, .error)

        proxy.enabled = false
        XCTAssertEqual(proxy.health, .disabled)
    }

    func testReportedErrorIsVisibleWithoutOnlineFlag() {
        var proxy = Proxy.fake()
        proxy.meta.nginx_online = nil
        proxy.meta.nginx_err = "bind failed"
        XCTAssertEqual(proxy.health, .error)
    }

    func testSearchIncludesAliasesAndUpstreamAddress() {
        var proxy = Proxy.fake()
        proxy.domain_names.append("Café.example.test")

        XCTAssertTrue(proxy.matchesSearch(" CAFE "))
        XCTAssertTrue(proxy.matchesSearch("192.168.68.251:5010"))
        XCTAssertTrue(proxy.matchesSearch("  "))
        XCTAssertFalse(proxy.matchesSearch("missing.example.test"))
    }
}
