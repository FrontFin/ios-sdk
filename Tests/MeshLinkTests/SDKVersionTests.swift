import Testing

@testable import MeshLink

/// CI already asserts that `VERSION` and `Version.swift` agree; this only checks
/// that the public value is wired to it.
@Suite("MeshLinkSDK")
struct SDKVersionTests {
    @Test func publicVersionIsTheSDKVersion() {
        #expect(MeshLinkSDK.version == SDKVersion.current)
    }
}
