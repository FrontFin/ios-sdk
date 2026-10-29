import Foundation

/// Where a WebView navigation request goes. Covered by the shared navigation
/// vectors N1–N9 (solution design §2.6).
enum NavigationDecision: Equatable {
    /// Load in the WebView.
    case load
    /// Cancel; the navigation reaches neither the WebView nor the OS.
    case block
    /// Hand `url` to the OS (wallet app, exchange app or browser). When opening
    /// it fails and `fallbackURL` is set, open that instead.
    case openExternal(url: String, fallbackURL: String? = nil)
}

enum NavigationPolicy {
    /// Schemes never loaded or handed to the OS from web content. `javascript:`
    /// and `data:` execute in whatever context receives them; `file:` and
    /// `content:` reach local storage; `android-app:` addresses an arbitrary
    /// component; `blob:` is meaningless outside the page; `http:` is cleartext.
    private static let blockedSchemes: Set<String> = [
        "javascript", "data", "file", "content", "android-app", "blob", "http"
    ]

    /// `about:` pages a frame may legitimately load (e.g. captcha iframes).
    private static let allowedAboutPages: Set<String> = ["about:blank", "about:srcdoc"]

    /// Where a navigation request goes.
    ///
    /// - The session's own Link origin loads in the WebView; any other `https`
    ///   page in the main frame (OAuth, on-ramp, exchange handoff) opens
    ///   externally, so universal links reach the wallet or exchange app.
    /// - Subframes may load any `https` page (captcha, payment iframes).
    /// - Custom schemes (wallet deep links) go to the OS.
    static func decideNavigation(
        url: String,
        isMainFrame: Bool,
        linkOrigin: String
    ) -> NavigationDecision {
        guard let scheme = URLOrigin.scheme(of: url), !blockedSchemes.contains(scheme) else {
            return .block
        }
        if scheme == "about" {
            return allowedAboutPages.contains(url.lowercased()) ? .load : .block
        }
        if scheme == "https" {
            if !isMainFrame || URLOrigin.origin(of: url) == linkOrigin {
                return .load
            }
            return .openExternal(url: url)
        }
        return externalAppDecision(url: url, scheme: scheme)
    }

    /// Where a `window.open()` / `target="_blank"` request goes. A new window
    /// never opens inside the SDK: `https` and wallet schemes leave the app,
    /// anything else is dropped.
    static func decideNewWindow(url: String) -> NavigationDecision {
        guard let scheme = URLOrigin.scheme(of: url),
              !blockedSchemes.contains(scheme),
              scheme != "about"
        else {
            return .block
        }
        if scheme == "https" {
            return .openExternal(url: url)
        }
        return externalAppDecision(url: url, scheme: scheme)
    }

    private static func externalAppDecision(url: String, scheme: String) -> NavigationDecision {
        if scheme == "intent" {
            return intentDecision(url: url)
        }
        // Deliberately not gated on `canOpenURL`: iOS caps
        // `LSApplicationQueriesSchemes` at 50, so it answers false for wallets
        // the integrator's Info.plist does not list.
        return .openExternal(url: url)
    }

    /// Android `intent://` URL → the plain deep link it describes, plus its
    /// `browser_fallback_url`. iOS does not receive `intent:` from WebKit, but
    /// the rule is kept so the shared vector set (N6) passes on every platform.
    private static func intentDecision(url: String) -> NavigationDecision {
        guard let fragmentRange = url.range(of: "#Intent;") else {
            return .block
        }
        let target = String(url[url.index(url.startIndex, offsetBy: "intent://".count)..<fragmentRange.lowerBound])
        var fields: [String: String] = [:]
        for part in url[fragmentRange.upperBound...].split(separator: ";", omittingEmptySubsequences: true) {
            if let separator = part.firstIndex(of: "="), separator > part.startIndex {
                fields[String(part[part.startIndex..<separator])] = String(part[part.index(after: separator)...])
            }
        }

        let fallbackURL = decodeFallback(fields["S.browser_fallback_url"])
        let scheme = fields["scheme"]?.lowercased()
        let launchable = scheme.map { isLaunchableScheme($0) } ?? false

        if let scheme, launchable {
            let deepLink = "\(scheme)://\(target)"
            return .openExternal(url: deepLink, fallbackURL: fallbackURL)
        }
        if let fallbackURL {
            return .openExternal(url: fallbackURL)
        }
        return .block
    }

    private static func isLaunchableScheme(_ scheme: String) -> Bool {
        guard let first = scheme.first, first.isLetter else {
            return false
        }
        let valid = scheme.allSatisfy { $0.isLetter || $0.isNumber || $0 == "+" || $0 == "." || $0 == "-" }
        return valid && !blockedSchemes.contains(scheme) && scheme != "intent" && scheme != "about"
    }

    private static func decodeFallback(_ value: String?) -> String? {
        guard let value, let decoded = value.removingPercentEncoding else {
            return nil
        }
        guard URLOrigin.scheme(of: decoded) == "https", URLOrigin.origin(of: decoded) != nil else {
            return nil
        }
        return decoded
    }
}
