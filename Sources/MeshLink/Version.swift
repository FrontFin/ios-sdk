// The SDK's own version. Committed (not generated): Swift Package Manager builds
// from source and has no manifest version to read at install time, so the value
// Link is told in the `meshSDKSpecs` handshake must live here.
//
// This file and the top-level `VERSION` file are bumped together in the release
// PR; CI fails when they disagree. The release tag must equal this value (tagged
// by hand until a release workflow is added). Do not hand-edit one without the
// other.

enum SDKVersion {
    static let current = "0.1.0"
}

/// Information about the MeshLink SDK itself.
public enum MeshLinkSDK {
    /// The SDK version, e.g. `"1.0.0"`. Include it in bug reports and logs.
    public static let version = SDKVersion.current
}
