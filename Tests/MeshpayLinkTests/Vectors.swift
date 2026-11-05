import Foundation

/// Loads the shared mobile-SDK test vectors from the repo's `test-vectors/`
/// directory (resolved from this file's path), so the iOS SDK is checked against
/// the exact same U1–U7 / N1–N8 cases as the other platforms.
enum Vectors {
    static func data(_ name: String) throws -> Data {
        let thisFile = URL(fileURLWithPath: #filePath)
        let root = thisFile
            .deletingLastPathComponent() // Tests/MeshpayLinkTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root
        let url = root.appendingPathComponent("test-vectors").appendingPathComponent(name)
        return try Data(contentsOf: url)
    }
}
