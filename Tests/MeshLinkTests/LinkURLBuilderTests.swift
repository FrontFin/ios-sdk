import Foundation
import Testing

@testable import MeshLink

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

    func toOptions() -> LinkOptions {
        LinkOptions(
            environment: environment.flatMap(LinkEnvironment.init(rawValue:)) ?? .prod,
            language: language,
            theme: theme.flatMap(LinkTheme.init(rawValue:)),
            integrationId: integrationId,
            displayFiatCurrency: displayFiatCurrency
        )
    }
}

@Suite("Link URL — shared vectors")
struct LinkURLVectorTests {
    static let vectors: [URLVector] = {
        let data = try! Vectors.data("link-url.json")
        return try! JSONDecoder().decode(URLVectorFile.self, from: data).vectors
    }()

    @Test(arguments: vectors)
    func matchesVector(_ vector: URLVector) throws {
        let build = {
            try LinkURLBuilder.build(
                token: vector.input.token,
                clientId: vector.input.clientId,
                options: vector.input.options.toOptions()
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
    @Test func reportsOriginForEnvironment() throws {
        let sbx = try LinkURLBuilder.build(token: "t", clientId: "c", options: LinkOptions(environment: .sbx))
        #expect(sbx.origin == "https://link.sbx.meshpay.com")
    }

    @Test func rejectsBlankToken() {
        #expect(throws: LinkURLBuildError.blankToken) {
            _ = try LinkURLBuilder.build(token: "  ", clientId: "c", options: LinkOptions())
        }
    }

    @Test func rejectsBlankClientId() {
        #expect(throws: LinkURLBuildError.blankClientId) {
            _ = try LinkURLBuilder.build(token: "t", clientId: "", options: LinkOptions())
        }
    }

    @Test func formEncodesLikeURLSearchParams() throws {
        let built = try LinkURLBuilder.build(
            token: "a b!'()~*",
            clientId: "c&d=e",
            options: LinkOptions(language: "pt-BR")
        )
        #expect(built.href == "https://link.meshpay.com/?token=a+b%21%27%28%29%7E*&clientId=c%26d%3De&lng=pt-BR")
    }

    @Test(arguments: [LinkTheme.light, .dark, .system])
    func passesThemeThroughAsIs(_ theme: LinkTheme) throws {
        let built = try LinkURLBuilder.build(token: "t", clientId: "c", options: LinkOptions(theme: theme))
        #expect(built.href == "https://link.meshpay.com/?token=t&clientId=c&th=\(theme.rawValue)")
    }

    @Test func omitsThemeWhenUnset() throws {
        let built = try LinkURLBuilder.build(token: "t", clientId: "c", options: LinkOptions())
        #expect(!built.href.contains("th="))
    }
}

extension URLVector: CustomTestStringConvertible {
    var testDescription: String { id }
}
