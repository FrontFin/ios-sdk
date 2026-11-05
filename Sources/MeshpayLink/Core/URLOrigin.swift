import Foundation

/// Small, strict URL helpers. Deliberately not `URLComponents`: these mirror the
/// shared mobile-SDK helpers byte-for-byte so the navigation policy and bridge
/// origin check behave identically across platforms, including on inputs
/// (custom schemes, credentials, odd ports) that `URLComponents` normalises or
/// rejects differently.
enum URLOrigin {
    private static let defaultPorts: [String: String] = ["http": "80", "https": "443"]

    /// Lower-cased scheme of `url` (`"https"`, `"metamask"`, …), or `nil`.
    static func scheme(of url: String) -> String? {
        if url.contains(where: \.isWhitespace) {
            return nil
        }
        guard let colon = url.firstIndex(of: ":") else {
            return nil
        }
        let scheme = String(url[url.startIndex..<colon])
        guard isValidScheme(scheme) else {
            return nil
        }
        return scheme.lowercased()
    }

    /// `scheme://host[:port]` of a hierarchical URL, lower-cased with the default
    /// port dropped, or `nil` when there is none. URLs with credentials
    /// (`https://a@b`) or whitespace are rejected rather than normalised.
    static func origin(of url: String) -> String? {
        if url.contains(where: \.isWhitespace) {
            return nil
        }
        guard let scheme = scheme(of: url) else {
            return nil
        }
        let afterScheme = url.dropFirst(scheme.count) // scheme was matched case-insensitively
        guard afterScheme.hasPrefix("://") else {
            return nil
        }
        let afterSlashes = afterScheme.dropFirst(3)
        // Authority runs up to the first '/', '?' or '#'.
        let authority = afterSlashes.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        if authority.isEmpty || authority.contains("@") {
            return nil
        }
        let parts = authority.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let host = parts[0].lowercased()
        guard !host.isEmpty, isValidHost(host) else {
            return nil
        }
        if parts.count == 2 {
            let port = String(parts[1])
            guard !port.isEmpty, port.unicodeScalars.allSatisfy(isASCIIDigit), port.count <= 5 else {
                return nil
            }
            if port != defaultPorts[scheme] {
                return "\(scheme)://\(host):\(port)"
            }
        }
        return "\(scheme)://\(host)"
    }

    /// True only for an `https://*.localcan.dev` tunnel URL. Subdomains only: the
    /// apex `localcan.dev` is the vendor site, not a tunnel.
    static func isLocalCanTunnel(_ value: String) -> Bool {
        guard let origin = origin(of: value), origin.hasPrefix("https://") else {
            return false
        }
        let host = origin.dropFirst("https://".count).prefix { $0 != ":" }
        return host.hasSuffix(".localcan.dev")
    }

    // The character checks below are ASCII-only, matching the shared regexes
    // (`[a-z][a-z0-9+.-]*`, `[a-z0-9.-]+`, `\d{1,5}`). Swift's `isLetter` and
    // `isNumber` are Unicode-aware and would also accept `é`, Cyrillic look-alikes
    // or Arabic-Indic digits, which the other SDKs reject.

    /// True for an RFC 3986 scheme: an ASCII letter, then ASCII letters, digits,
    /// `+`, `.` or `-`.
    static func isValidScheme(_ scheme: String) -> Bool {
        guard let first = scheme.unicodeScalars.first, isASCIILetter(first) else {
            return false
        }
        return scheme.unicodeScalars.allSatisfy {
            isASCIILetter($0) || isASCIIDigit($0) || $0 == "+" || $0 == "." || $0 == "-"
        }
    }

    private static func isValidHost(_ host: String) -> Bool {
        host.unicodeScalars.allSatisfy { isASCIILetter($0) || isASCIIDigit($0) || $0 == "." || $0 == "-" }
    }

    private static func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar)
    }

    private static func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(scalar)
    }
}
