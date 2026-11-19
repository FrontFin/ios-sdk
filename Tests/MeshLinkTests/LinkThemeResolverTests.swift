import Foundation
import Testing

@testable import MeshLink

/// base64url without padding.
private func envelope(_ json: String) -> String {
    Data(json.utf8).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

/// Realistic tokens: unpadded base64url containing both `-` and `_`.
private let darkEnvelope =
    "eyJ2IjoxLCJjIjoiZDJmMWM3ZTAtOWIxYS00YzNlLThmN2EtM2IyZTFkMGM5Zjhlfj8-IiwidGgiOiJMSU5LX1RIRU1FX0RBUksiLCJsaWwiOiJodHRwczovL2Nkbi5leGF"
    + "tcGxlLmNvbS9sb2dvLWxpZ2h0LnBuZz93PTEyOCZoPTEyOCIsImJnbCI6IiNGRkZGRkYifQ"
private let lightEnvelope =
    "eyJ2IjoxLCJjIjoiZDJmMWM3ZTAtOWIxYS00YzNlLThmN2EtM2IyZTFkMGM5Zjhlfj8-IiwidGgiOiJMSU5LX1RIRU1FX0xJR0hUIiwibGlsIjoiaHR0cHM6Ly9jZG4uZXh"
    + "hbXBsZS5jb20vbG9nby1saWdodC5wbmc_dz0xMjgmaD0xMjgiLCJiZ2wiOiIjRkZGRkZGIn0"

@Suite("Session token theme")
struct SessionTokenThemeTests {
    @Test func readsDarkFromRealisticEnvelope() {
        #expect(SessionToken.themeIsDark(darkEnvelope) == true)
    }

    @Test func readsLightFromRealisticEnvelope() {
        #expect(SessionToken.themeIsDark(lightEnvelope) == false)
    }

    @Test func acceptsPaddedStandardBase64() {
        let json = #"{"v":1,"c":"code","th":"LINK_THEME_DARK"}"#
        #expect(SessionToken.themeIsDark(Data(json.utf8).base64EncodedString()) == true)
    }

    @Test(arguments: [
        ("raw legacy token", "tok_123"),
        ("raw uuid token", "d2f1c7e0-9b1a-4c3e-8f7a-3b2e1d0c9f8e"),
        ("empty", ""),
        ("malformed base64", "!!!not*base64!!!"),
        ("impossible length", "abcde"),
        ("not JSON", envelope("hello world")),
        ("JSON array", envelope(#"[{"v":1,"c":"code","th":"LINK_THEME_DARK"}]"#)),
        ("JSON string", envelope(#""LINK_THEME_DARK""#)),
        ("no th", envelope(#"{"v":1,"c":"code"}"#)),
        ("unspecified th", envelope(#"{"v":1,"c":"code","th":"LINK_THEME_UNSPECIFIED"}"#)),
        ("lower-case th", envelope(#"{"v":1,"c":"code","th":"dark"}"#)),
        ("numeric th", envelope(#"{"v":1,"c":"code","th":2}"#)),
        ("null th", envelope(#"{"v":1,"c":"code","th":null}"#)),
        ("missing v", envelope(#"{"c":"code","th":"LINK_THEME_DARK"}"#)),
        ("string v", envelope(#"{"v":"1","c":"code","th":"LINK_THEME_DARK"}"#)),
        ("boolean v", envelope(#"{"v":true,"c":"code","th":"LINK_THEME_DARK"}"#)),
        ("missing c", envelope(#"{"v":1,"th":"LINK_THEME_DARK"}"#)),
        ("empty c", envelope(#"{"v":1,"c":"","th":"LINK_THEME_DARK"}"#)),
        ("numeric c", envelope(#"{"v":1,"c":7,"th":"LINK_THEME_DARK"}"#))
    ])
    func noThemeFor(_ label: String, _ token: String) {
        #expect(SessionToken.themeIsDark(token) == nil, "\(label)")
    }
}

@Suite("Native UI theme resolution")
struct LinkThemeResolverTests {
    @Test(arguments: [false, true])
    func explicitThemeWinsOverTokenAndDevice(_ device: Bool) {
        for token in [darkEnvelope, lightEnvelope, "tok_123"] {
            #expect(LinkThemeResolver.isDark(theme: .light, token: token, isDarkAppearance: device) == false)
            #expect(LinkThemeResolver.isDark(theme: .dark, token: token, isDarkAppearance: device) == true)
        }
    }

    @Test(arguments: [LinkTheme.system, nil])
    func tokenDarkBeatsLightDevice(_ theme: LinkTheme?) {
        #expect(LinkThemeResolver.isDark(theme: theme, token: darkEnvelope, isDarkAppearance: false) == true)
    }

    @Test(arguments: [LinkTheme.system, nil])
    func tokenLightBeatsDarkDevice(_ theme: LinkTheme?) {
        #expect(LinkThemeResolver.isDark(theme: theme, token: lightEnvelope, isDarkAppearance: true) == false)
    }

    @Test(arguments: [
        "tok_123",
        "!!!not*base64!!!",
        envelope(#"{"v":1,"c":"code"}"#),
        envelope(#"{"v":1,"c":"code","th":"LINK_THEME_UNSPECIFIED"}"#),
        envelope(#"[1,2,3]"#)
    ])
    func fallsBackToDevice(_ token: String) {
        for theme in [LinkTheme.system, nil] {
            for device in [false, true] {
                #expect(LinkThemeResolver.isDark(theme: theme, token: token, isDarkAppearance: device) == device)
            }
        }
    }
}
