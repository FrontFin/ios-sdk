import Foundation
import Testing

import MeshLink

@Suite("MeshLinkSDK")
struct SDKVersionTests {
    @Test func publicVersionMatchesTheVersionFile() throws {
        let versionFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // MeshLinkTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // package root
            .appendingPathComponent("VERSION")
        let expected = try String(contentsOf: versionFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(MeshLinkSDK.version == expected)
    }
}
