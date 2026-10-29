import Testing

@testable import MeshpayLink

@Suite("URL origin helpers")
struct URLOriginTests {
    @Test func matchesOnlyTheSessionOrigin() {
        #expect(URLOrigin.origin(of: "https://link.meshpay.com/deposit") == "https://link.meshpay.com")
        #expect(URLOrigin.origin(of: "https://LINK.meshpay.com:443/") == "https://link.meshpay.com")
        #expect(URLOrigin.origin(of: "https://link.meshpay.com:8443/") == "https://link.meshpay.com:8443")
        #expect(URLOrigin.origin(of: "https://evil.example/") == "https://evil.example")
    }

    @Test func rejectsCredentialsAndWhitespace() {
        #expect(URLOrigin.origin(of: "https://link.meshpay.com@evil.com/") == nil)
        #expect(URLOrigin.origin(of: "https://link.meshpay.com /x") == nil)
        #expect(URLOrigin.origin(of: "not a url") == nil)
    }

    @Test func readsTheScheme() {
        #expect(URLOrigin.scheme(of: "https://link.meshpay.com") == "https")
        #expect(URLOrigin.scheme(of: "METAMASK://wc") == "metamask")
        #expect(URLOrigin.scheme(of: "link.meshpay.com") == nil)
    }

    @Test func recognisesLocalCanTunnels() {
        #expect(URLOrigin.isLocalCanTunnel("https://abc123.localcan.dev"))
        #expect(URLOrigin.isLocalCanTunnel("https://abc123.localcan.dev:8443/app"))
        #expect(!URLOrigin.isLocalCanTunnel("https://localcan.dev"))
        #expect(!URLOrigin.isLocalCanTunnel("http://abc123.localcan.dev"))
        #expect(!URLOrigin.isLocalCanTunnel("https://evil.example.com"))
    }
}
