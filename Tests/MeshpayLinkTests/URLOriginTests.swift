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

    // ASCII only, like the shared regexes: Swift's `isLetter` / `isNumber` would
    // accept all of these.
    @Test func rejectsNonASCIISchemes() {
        #expect(URLOrigin.scheme(of: "m\u{E9}tamask:wc?uri=1") == nil) // é
        #expect(URLOrigin.scheme(of: "m\u{435}tamask:wc?uri=1") == nil) // Cyrillic е
        #expect(URLOrigin.scheme(of: "\u{3B1}pp:x") == nil) // Greek α first
    }

    @Test func rejectsNonASCIIHostsAndPorts() {
        #expect(URLOrigin.origin(of: "https://m\u{FC}nchen.de/a") == nil) // ü
        #expect(URLOrigin.origin(of: "https://link.m\u{435}shpay.com/") == nil) // Cyrillic е
        #expect(URLOrigin.origin(of: "https://x.example:\u{661}\u{662}\u{663}/") == nil) // Arabic-Indic 123
        #expect(URLOrigin.origin(of: "https://x.example:\u{BD}/") == nil) // ½
        #expect(URLOrigin.origin(of: "https://xn--mnchen-3ya.de/a") == "https://xn--mnchen-3ya.de")
    }

    @Test func recognisesLocalCanTunnels() {
        #expect(URLOrigin.isLocalCanTunnel("https://abc123.localcan.dev"))
        #expect(URLOrigin.isLocalCanTunnel("https://abc123.localcan.dev:8443/app"))
        #expect(!URLOrigin.isLocalCanTunnel("https://localcan.dev"))
        #expect(!URLOrigin.isLocalCanTunnel("http://abc123.localcan.dev"))
        #expect(!URLOrigin.isLocalCanTunnel("https://evil.example.com"))
    }
}
