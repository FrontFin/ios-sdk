import Testing

@testable import MeshpayLink

@Suite("LinkErrorCode")
struct LinkErrorCodeTests {
    @Test func keepsTheSharedWireStrings() {
        #expect(LinkErrorCode.loadError.rawValue == "load-error")
        #expect(LinkErrorCode.loadTimeout.rawValue == "load-timeout")
        #expect(LinkErrorCode.sessionInterrupted.rawValue == "session-interrupted")
    }

    @Test func roundTripsKnownAndUnknownCodes() {
        #expect(LinkErrorCode(rawValue: "load-error") == .loadError)
        let future = LinkErrorCode(rawValue: "some-future-code")
        #expect(future.rawValue == "some-future-code")
        #expect(future != .loadError)
        #expect(future.description == "some-future-code")
    }

    @Test func matchesInASwitch() {
        func label(_ code: LinkErrorCode) -> String {
            switch code {
            case .loadError: "error"
            case .loadTimeout: "timeout"
            case .sessionInterrupted: "interrupted"
            default: "unknown"
            }
        }
        #expect(label(.loadTimeout) == "timeout")
        #expect(label(LinkErrorCode(rawValue: "x")) == "unknown")
    }
}
