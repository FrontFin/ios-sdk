// The SDK's own version. Committed (not generated): Swift Package Manager builds
// from source and has no manifest version to read at install time, so the value
// Link is told in the `meshSDKSpecs` handshake must live here.
//
// This file and the top-level `VERSION` file are bumped together in the release
// PR; CI fails when they disagree, and the release job fails when the git tag
// does not match. Do not hand-edit one without the other.

enum SDKVersion {
    static let current = "0.1.0"
}
