import Foundation
import Testing

@testable import MeshLink

@Suite("Bridge message parsing")
struct BridgeMessageTests {
    @Test(arguments: [
        ("success", "success", LinkExitStatus.success),
        ("canceled", "canceled", .canceled),
        ("unknown status", "done", .canceled)
    ])
    func readsCloseStatusFromPayload(_ label: String, _ status: String, _ expected: LinkExitStatus) {
        let json = "{\"type\":\"close\",\"payload\":{\"status\":\"\(status)\"}}"
        #expect(BridgeMessage.parse(json) == .close(status: expected), "\(label)")
    }

    @Test func readsCloseWithoutPayloadAsCanceled() {
        #expect(BridgeMessage.parse("{\"type\":\"close\"}") == .close(status: .canceled))
        #expect(BridgeMessage.parse("{\"type\":\"close\",\"payload\":null}") == .close(status: .canceled))
    }

    @Test func readsLoaded() {
        #expect(BridgeMessage.parse("{\"type\":\"loaded\"}") == .loaded)
    }

    @Test func acceptsAnAlreadyParsedDictionary() {
        #expect(BridgeMessage.parse(["type": "loaded"]) == .loaded)
        let close: [String: Any] = ["type": "close", "payload": ["status": "success"]]
        #expect(BridgeMessage.parse(close) == .close(status: .success))
    }

    @Test(arguments: [
        "{not json",
        "\"close\"",
        "null",
        "[{\"type\":\"close\"}]",
        "{\"payload\":{}}",
        "{\"type\":\"transferFinished\",\"payload\":{\"userId\":\"u\"}}",
        "{\"type\":\"brokerageAccountAccessToken\"}"
    ])
    func ignoresUnknownOrMalformedStrings(_ data: String) {
        #expect(BridgeMessage.parse(data) == nil)
    }

    @Test func ignoresNonStringNonObjectBodies() {
        #expect(BridgeMessage.parse(42) == nil)
        #expect(BridgeMessage.parse(nil) == nil)
        #expect(BridgeMessage.parse([1, 2, 3]) == nil)
    }
}
