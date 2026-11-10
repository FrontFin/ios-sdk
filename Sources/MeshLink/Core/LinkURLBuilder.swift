import Foundation

/// Builds the Link UI URL:
/// the parameters `token`, `clientId`, `lng`, `th`, `integrationId`, `fiatCur`,
/// in that order, each only when set, form-encoded. Covered by the shared URL
/// vectors in `test-vectors/link-url.json` (solution design §2.4).
/// A blank input reaching the pure URL builder. The public surface
/// (``LinkSession``) rejects blanks before this point and reports them through
/// `onError`; this error is the builder's own guard and the U7 vector's expected
/// failure.
enum LinkURLBuildError: Error, Equatable {
    case blankToken
    case blankClientId
}

enum LinkURLBuilder {
    struct Built: Equatable {
        /// The full URL string to load.
        let href: String
        /// Origin of the Link page. Bridge messages and main-frame navigations
        /// from any other origin are treated as external.
        let origin: String
    }

    /// - Parameters:
    ///   - isDarkAppearance: the device appearance, used to resolve a `system`
    ///     theme to `light`/`dark` at open time.
    /// - Throws: ``LinkURLBuildError`` when `token` or `clientId` is blank.
    static func build(
        token: String,
        clientId: String,
        options: LinkOptions,
        isDarkAppearance: Bool
    ) throws -> Built {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            throw LinkURLBuildError.blankToken
        }
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientId.isEmpty else {
            throw LinkURLBuildError.blankClientId
        }

        let base = Constants.linkURLs[options.environment] ?? Constants.linkURLs[.prod]!

        var params: [(String, String)] = [
            ("token", trimmedToken),
            ("clientId", trimmedClientId)
        ]
        if let language = options.language {
            params.append(("lng", language))
        }
        if let theme = options.theme {
            params.append(("th", resolveTheme(theme, isDarkAppearance: isDarkAppearance)))
        }
        if let integrationId = options.integrationId {
            params.append(("integrationId", integrationId))
        }
        if let fiatCurrency = options.displayFiatCurrency {
            params.append(("fiatCur", fiatCurrency))
        }

        let href = appendQuery(to: base, params: params)
        // `base` is one of the environment constants, so it always has an origin.
        let origin = URLOrigin.origin(of: href) ?? base
        return Built(href: href, origin: origin)
    }

    /// `light` or `dark`; `system` follows the device appearance (light when the
    /// device is not in dark mode).
    static func resolveTheme(_ theme: LinkTheme, isDarkAppearance: Bool) -> String {
        switch theme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        case .system:
            return isDarkAppearance ? "dark" : "light"
        }
    }

    private static func appendQuery(to base: String, params: [(String, String)]) -> String {
        let hashSplit = base.firstIndex(of: "#")
        let withoutHash = hashSplit.map { String(base[base.startIndex..<$0]) } ?? base
        let hash = hashSplit.map { String(base[$0...]) } ?? ""

        // `URL("https://host")` normalises to `https://host/`; match it.
        let withPath = isSchemeAndAuthorityOnly(withoutHash) ? withoutHash + "/" : withoutHash
        let query = params.map { "\(formEncode($0.0))=\(formEncode($0.1))" }.joined(separator: "&")
        let separator = withPath.contains("?") ? "&" : "?"
        return "\(withPath)\(separator)\(query)\(hash)"
    }

    /// True for `scheme://authority` with no path, query or fragment.
    private static func isSchemeAndAuthorityOnly(_ value: String) -> Bool {
        guard let range = value.range(of: "://") else {
            return false
        }
        let authority = value[range.upperBound...]
        return !authority.isEmpty && !authority.contains(where: { $0 == "/" || $0 == "?" || $0 == "#" })
    }

    /// application/x-www-form-urlencoded, byte-for-byte like `URLSearchParams`:
    /// everything but `A–Z a–z 0–9 - _ . *` percent-encoded (upper-case hex),
    /// space as `+`.
    private static func formEncode(_ value: String) -> String {
        let encoded = value.addingPercentEncoding(withAllowedCharacters: Self.unreserved) ?? value
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }

    private static let unreserved: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.*")
        return set
    }()
}
