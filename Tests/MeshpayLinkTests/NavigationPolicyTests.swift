import Foundation
import Testing

@testable import MeshpayLink

struct NavVectorFile: Decodable {
    let linkOrigin: String
    let vectors: [NavVector]
}

struct NavVector: Decodable {
    let id: String
    let url: String
    let isTopFrame: Bool?
    let newWindow: Bool?
    let expected: ExpectedDecision
}

struct ExpectedDecision: Decodable {
    let action: String
    let url: String?
    let fallbackUrl: String?

    func decision() -> NavigationDecision {
        switch action {
        case "load": return .load
        case "block": return .block
        case "open-external": return .openExternal(url: url ?? "", fallbackURL: fallbackUrl)
        default: return .block
        }
    }
}

@Suite("Navigation policy — shared vectors (N1–N8)")
struct NavigationVectorTests {
    static let file: NavVectorFile = {
        let data = try! Vectors.data("navigation.json")
        return try! JSONDecoder().decode(NavVectorFile.self, from: data)
    }()

    @Test(arguments: file.vectors)
    func matchesVector(_ vector: NavVector) {
        let decision: NavigationDecision
        if vector.newWindow == true {
            decision = NavigationPolicy.decideNewWindow(url: vector.url)
        } else {
            decision = NavigationPolicy.decideNavigation(
                url: vector.url,
                isMainFrame: vector.isTopFrame ?? true,
                linkOrigin: NavigationVectorTests.file.linkOrigin
            )
        }
        #expect(decision == vector.expected.decision(), "vector \(vector.id)")
    }
}

private let link = "https://link.meshpay.com"

@Suite("Navigation policy — extra cases")
struct NavigationPolicyExtraTests {
    @Test func blocksURLsWithoutSchemeOrWithWhitespace() {
        #expect(NavigationPolicy.decideNavigation(url: "", isMainFrame: true, linkOrigin: link) == .block)
        #expect(NavigationPolicy.decideNavigation(url: "link.meshpay.com", isMainFrame: true, linkOrigin: link) == .block)
        #expect(NavigationPolicy.decideNavigation(url: "metamask://wc ?uri=1", isMainFrame: true, linkOrigin: link) == .block)
    }

    @Test func treatsADifferentLinkEnvironmentAsExternal() {
        #expect(
            NavigationPolicy.decideNavigation(url: "https://link.sbx.meshpay.com/", isMainFrame: true, linkOrigin: link)
                == .openExternal(url: "https://link.sbx.meshpay.com/")
        )
    }

    @Test func doesNotTrustALookalikeHostWithCredentials() {
        #expect(
            NavigationPolicy.decideNavigation(url: "https://link.meshpay.com@evil.com/", isMainFrame: true, linkOrigin: link)
                == .openExternal(url: "https://link.meshpay.com@evil.com/")
        )
    }

    @Test func handsCustomSchemesFromSubframesToTheOS() {
        #expect(
            NavigationPolicy.decideNavigation(url: "trust://open", isMainFrame: false, linkOrigin: link)
                == .openExternal(url: "trust://open")
        )
    }

    @Test func allowsAboutSrcdocFrames() {
        #expect(NavigationPolicy.decideNavigation(url: "about:srcdoc", isMainFrame: false, linkOrigin: link) == .load)
    }

    @Test func blocksMalformedIntentWithoutAuthority() {
        // Regression: a non-hierarchical `intent:` URL whose fragment precedes
        // the assumed `intent://` prefix length must be blocked, not crash.
        #expect(NavigationPolicy.decideNavigation(url: "intent:#Intent;scheme=metamask;end", isMainFrame: true, linkOrigin: link) == .block)
        #expect(NavigationPolicy.decideNavigation(url: "intent:#Intent;end", isMainFrame: true, linkOrigin: link) == .block)
        // A well-formed intent:// with an empty target still resolves safely.
        #expect(
            NavigationPolicy.decideNavigation(url: "intent://#Intent;scheme=metamask;end", isMainFrame: true, linkOrigin: link)
                == .openExternal(url: "metamask://")
        )
    }

    @Test func blocksNonASCIISchemes() {
        // A Cyrillic look-alike of `metamask:` is not a scheme, so it is blocked
        // rather than handed to the OS.
        let lookalike = "m\u{435}tamask://wc?uri=1"
        #expect(NavigationPolicy.decideNavigation(url: lookalike, isMainFrame: true, linkOrigin: link) == .block)
        #expect(NavigationPolicy.decideNewWindow(url: lookalike) == .block)
        // The same through an Android intent's `scheme=` field: not launchable.
        #expect(
            NavigationPolicy.decideNavigation(url: "intent://wc#Intent;scheme=m\u{E9}tamask;end", isMainFrame: true, linkOrigin: link)
                == .block
        )
    }

    @Test func decideNewWindowOpensWalletSchemesAndBlocksUnsafeOnes() {
        #expect(NavigationPolicy.decideNewWindow(url: "metamask://wc") == .openExternal(url: "metamask://wc"))
        #expect(NavigationPolicy.decideNewWindow(url: "javascript:alert(1)") == .block)
        #expect(NavigationPolicy.decideNewWindow(url: "about:blank") == .block)
        #expect(NavigationPolicy.decideNewWindow(url: "") == .block)
    }
}

extension NavVector: CustomTestStringConvertible {
    var testDescription: String { id }
}
