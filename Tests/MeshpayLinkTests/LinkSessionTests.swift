#if canImport(UIKit)
import Testing

@testable import MeshpayLink

@Suite("LinkSession configuration")
struct LinkSessionTests {
    @Test @MainActor func throwsOnBlankToken() {
        #expect(throws: LinkConfigurationError.blankToken) {
            _ = try LinkSession(token: "   ", clientId: "c", onExit: { _ in }, onError: { _ in })
        }
    }

    @Test @MainActor func throwsOnBlankClientId() {
        #expect(throws: LinkConfigurationError.blankClientId) {
            _ = try LinkSession(token: "t", clientId: "", onExit: { _ in }, onError: { _ in })
        }
    }

    @Test @MainActor func succeedsWithValidValues() throws {
        // Trimmed, non-blank values: the initializer does not throw.
        _ = try LinkSession(token: " t ", clientId: " c ", onExit: { _ in }, onError: { _ in })
    }
}
#endif
