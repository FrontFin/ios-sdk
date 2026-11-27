import Foundation

/// Picks the appearance for the native UI around Link so it matches Link.
enum LinkThemeResolver {
    static func isDark(theme: LinkTheme?, token: String, isDarkAppearance: Bool) -> Bool {
        switch theme {
        case .light:
            return false
        case .dark:
            return true
        case .system, nil:
            return SessionToken.themeIsDark(token) ?? isDarkAppearance
        }
    }
}

/// Reads the theme Link will use from the session token, if present.
///
/// Never log the token or any part of it.
enum SessionToken {
    /// `true` for dark, `false` for light, nil when the token carries no theme.
    static func themeIsDark(_ token: String) -> Bool? {
        guard let envelope = decodeEnvelope(token) else {
            return nil
        }
        switch envelope["th"] as? String {
        case "LINK_THEME_DARK":
            return true
        case "LINK_THEME_LIGHT":
            return false
        default:
            return nil
        }
    }

    /// The decoded token payload, or nil when the token has none.
    private static func decodeEnvelope(_ token: String) -> [String: Any]? {
        var base64 = token.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: base64),
              let object = try? JSONSerialization.jsonObject(with: data),
              let envelope = object as? [String: Any],
              isNumber(envelope["v"]),
              let code = envelope["c"] as? String,
              !code.isEmpty
        else {
            return nil
        }
        return envelope
    }

    /// `JSONSerialization` bridges booleans to `NSNumber` too; exclude them.
    private static func isNumber(_ value: Any?) -> Bool {
        guard let number = value as? NSNumber else {
            return false
        }
        return CFGetTypeID(number) != CFBooleanGetTypeID()
    }
}
