import CoreGraphics
import Foundation

/// Values fixed by the hosted Link contract and the solution design. Shared
/// across the mobile SDKs; keep in sync.
enum Constants {
    /// Base URL per environment.
    static let linkURLs: [LinkEnvironment: String] = [
        .dev: "https://link.dev.meshpay.com",
        .prod: "https://link.meshpay.com",
        .sbx: "https://link.sbx.meshpay.com"
    ]

    /// Platform identifier announced to Link. Link only recognises this exact,
    /// case-sensitive string on iOS.
    static let sdkPlatform = "iOS"

    /// How long to wait for the Link page to load before reporting
    /// ``LinkErrorCode/loadTimeout``.
    static let loadTimeout: TimeInterval = 15

    /// How long a host-initiated close waits for Link to answer `closeRequested`
    /// with its own `close` (which carries the session status) before tearing
    /// down anyway.
    static let closeGrace: TimeInterval = 1

    /// How long the native close button stays hidden after a session opens. If
    /// Link reports `loaded` sooner, it never appears (Link draws its own close).
    static let closeButtonDelay: TimeInterval = 3

    /// Background shown behind the WebView while Link loads, per resolved theme.
    enum BackgroundColor {
        static let darkHex = "#0E0D0D"
        static let lightHex = "#FBFBFB"
    }
}
