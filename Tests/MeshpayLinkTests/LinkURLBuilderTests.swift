import Foundation
import Testing

@testable import MeshpayLink

struct URLVectorFile: Decodable {
    let vectors: [URLVector]
}

struct URLVector: Decodable {
    let id: String
    let input: Input
    let expected: String?
    let expectedError: Bool?

    struct Input: Decodable {
        let token: String
        let clientId: String
        let options: OptionsJSON
        let colorScheme: String?
    }
}

struct OptionsJSON: Decodable {
    let environment: String?
    let language: String?
    let theme: String?
    let integrationId: String?
    let displayFiatCurrency: String?
    let linkUrl: String?

    func toOptions() -> LinkOptions {
        LinkOptions(
            environment: environment.flatMap(LinkEnvironment.init(rawValue:)) ?? .prod,
            language: language,
            theme: theme.flatMap(LinkTheme.init(rawValue:)),
            integrationId: integrationId,
            displayFiatCurrency: displayFiatCurrency,
            linkUrl: linkUrl
        )
    }
}

@Suite("Link URL — shared vectors (U1–U12)")
struct LinkURLVectorTests {
    static let vectors: [URLVector] = {
        let data = try! Vectors.data("link-url.json")
        return try! JSONDecoder().decode(URLVectorFile.self, from: data).vectors
    }()

    @Test(arguments: vectors)
    func matchesVector(_ vector: URLVector) throws {
        let isDark = vector.input.colorScheme == "dark"
        let build = {
            try LinkURLBuilder.build(
                token: vector.input.token,
                clientId: vector.input.clientId,
                options: vector.input.options.toOptions(),
                isDarkAppearance: isDark
            )
        }
        if vector.expectedError == true {
            #expect(throws: LinkURLBuildError.self, "vector \(vector.id)") {
                _ = try build()
            }
        } else {
            let built = try build()
            #expect(built.href == vector.expected, "vector \(vector.id)")
        }
    }
}

@Suite("Link URL — builder")
struct LinkURLBuilderTests {
    @Test func reportsOriginForEnvironmentAndTunnel() throws {
        let sbx = try LinkURLBuilder.build(token: "t", clientId: "c", options: LinkOptions(environment: .sbx), isDarkAppearance: false)
        #expect(sbx.origin == "https://link.sbx.meshpay.com")

        let tunnel = try LinkURLBuilder.build(
            token: "t",
            clientId: "c",
            options: LinkOptions(linkUrl: "https://abc123.localcan.dev:8443/app"),
            isDarkAppearance: false
        )
        #expect(tunnel.origin == "https://abc123.localcan.dev:8443")
    }

    @Test func rejectsBlankToken() {
        #expect(throws: LinkURLBuildError.blankToken) {
            _ = try LinkURLBuilder.build(token: "  ", clientId: "c", options: LinkOptions(), isDarkAppearance: false)
        }
    }

    @Test func rejectsBlankClientId() {
        #expect(throws: LinkURLBuildError.blankClientId) {
            _ = try LinkURLBuilder.build(token: "t", clientId: "", options: LinkOptions(), isDarkAppearance: false)
        }
    }

    @Test func formEncodesLikeURLSearchParams() throws {
        let built = try LinkURLBuilder.build(
            token: "a b!'()~*",
            clientId: "c&d=e",
            options: LinkOptions(language: "pt-BR"),
            isDarkAppearance: false
        )
        #expect(built.href == "https://link.meshpay.com/?token=a+b%21%27%28%29%7E*&clientId=c%26d%3De&lng=pt-BR")
    }

    @Test func appendsToTunnelWithPathQueryAndHash() throws {
        let built = try LinkURLBuilder.build(
            token: "t",
            clientId: "c",
            options: LinkOptions(linkUrl: "https://abc123.localcan.dev/app?x=1#top"),
            isDarkAppearance: false
        )
        #expect(built.href == "https://abc123.localcan.dev/app?x=1&token=t&clientId=c#top")
    }

    @Test func resolvesTheme() {
        #expect(LinkURLBuilder.resolveTheme(.light, isDarkAppearance: true) == "light")
        #expect(LinkURLBuilder.resolveTheme(.dark, isDarkAppearance: false) == "dark")
        #expect(LinkURLBuilder.resolveTheme(.system, isDarkAppearance: true) == "dark")
        #expect(LinkURLBuilder.resolveTheme(.system, isDarkAppearance: false) == "light")
    }
}

extension URLVector: CustomTestStringConvertible {
    var testDescription: String { id }
}
