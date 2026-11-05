import Testing

@testable import MeshpayLink

@Suite("LinkExitStatus")
struct LinkExitStatusTests {
    @Test func keepsTheSharedWireStrings() {
        #expect(LinkExitStatus.success.rawValue == "success")
        #expect(LinkExitStatus.canceled.rawValue == "canceled")
    }

    @Test func roundTripsKnownAndUnknownStatuses() {
        #expect(LinkExitStatus(rawValue: "success") == .success)
        let future = LinkExitStatus(rawValue: "some-future-status")
        #expect(future.rawValue == "some-future-status")
        #expect(future != .success && future != .canceled)
        #expect(future.description == "some-future-status")
    }

    @Test func matchesInASwitch() {
        func label(_ status: LinkExitStatus) -> String {
            switch status {
            case .success: "done"
            case .canceled: "canceled"
            default: "unknown"
            }
        }
        #expect(label(.success) == "done")
        #expect(label(LinkExitStatus(rawValue: "x")) == "unknown")
    }
}
