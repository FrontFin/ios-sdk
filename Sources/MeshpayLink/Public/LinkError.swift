import Foundation

/// How a Link session ended, as reported by Link.
///
/// - `success` — the user completed the target action (submitted the deposit or
///   transfer, finished a verify-only or connect-only flow, confirmed a
///   withdrawal, created a fiat ramp transfer).
/// - `canceled` — anything else: the user dropped out, the last attempt failed,
///   or the session ended without Link reporting a status.
///
/// Use it to drive your UI, never as proof of payment — confirm the outcome
/// server-side.
public enum LinkExitStatus: String, Sendable, Equatable {
    case success
    case canceled
}

/// Passed to `onExit` when the session ends normally.
public struct LinkExitSummary: Sendable, Equatable {
    public let status: LinkExitStatus

    public init(status: LinkExitStatus) {
        self.status = status
    }
}

/// Why Link could not be shown or could not continue.
///
/// An open set: new codes can be added in minor versions, so a `switch` over a
/// code needs a `default` branch. `rawValue` is the wire string shared with the
/// other MeshPay SDKs (e.g. `"load-error"`).
public struct LinkErrorCode: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    /// The Link page failed to load (a network failure or an HTTP error on the
    /// page itself).
    public static let loadError = LinkErrorCode(rawValue: "load-error")
    /// The Link page did not finish loading within 15 s. A page that loads but
    /// never posts `loaded` is not covered.
    public static let loadTimeout = LinkErrorCode(rawValue: "load-timeout")
    /// The WebView's content process died mid-session and the session cannot
    /// resume.
    public static let sessionInterrupted = LinkErrorCode(rawValue: "session-interrupted")
}

/// Reported via `onError` when Link can't be shown or can't continue.
///
/// `message` is for developers only: it never contains the token, the Link URL
/// or a stack trace.
public struct LinkError: Error, Sendable, Equatable {
    public let code: LinkErrorCode
    public let message: String

    public init(code: LinkErrorCode, message: String) {
        self.code = code
        self.message = message
    }
}
