import Foundation

/// The JavaScript the SDK injects into the Link page. Every value is JSON-encoded,
/// never concatenated into the script, so a crafted version string can't inject
/// code (solution design §2.5, §2.7).
enum ScriptBuilder {
    /// Runs at document start in the main frame: announces the host to Link
    /// before any of its code runs. Link's `isLegacySdk()` and analytics read
    /// these globals.
    static func documentStartScript(version: String) -> String {
        "window.meshSdkPlatform = \(jsonString(Constants.sdkPlatform));"
            + "window.meshSdkVersion = \(jsonString(version));true;"
    }

    /// The `meshSDKSpecs` handshake, posted to the page after Link reports
    /// `loaded`. No `origin`: the native transport does not need one.
    static func sdkSpecsScript(version: String) -> String {
        let payload = "{\"type\":\"meshSDKSpecs\",\"payload\":{"
            + "\"platform\":\(jsonString(Constants.sdkPlatform)),"
            + "\"version\":\(jsonString(version))}}"
        return "window.postMessage(\(payload), '*');true;"
    }

    /// Asks Link to close gracefully, so it can report the session status.
    static func closeRequestedScript() -> String {
        "window.postMessage({\"type\":\"closeRequested\"}, '*');true;"
    }

    /// A JSON string literal for `value` (like `JSON.stringify`): quotes and
    /// backslashes escaped, control characters as `\u00XX`, everything else
    /// verbatim.
    static func jsonString(_ value: String) -> String {
        var result = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\u{08}": result += "\\b"
            case "\u{09}": result += "\\t"
            case "\u{0A}": result += "\\n"
            case "\u{0C}": result += "\\f"
            case "\u{0D}": result += "\\r"
            default:
                if scalar.value < 0x20 {
                    result += String(format: "\\u%04x", scalar.value)
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }
        result += "\""
        return result
    }
}
