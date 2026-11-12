# Mesh Link iOS SDK

Open the hosted **Mesh Link** UI full screen in an iOS app.

A thin native wrapper around `link.meshpay.com`: it builds the Link URL, shows it
in a `WKWebView`, speaks the Link bridge, routes wallet and OAuth hand-offs to the
OS, and reports exactly one outcome per session. **WebKit, UIKit and SwiftUI only
— no third-party dependencies.**

Distributed as `MeshLink` via Swift Package Manager.

## Requirements

- iOS 15+
- Swift 6 / Xcode 16+

## Install

Add the package in Xcode (**File ▸ Add Package Dependencies…**) with the repository
URL:

```
https://github.com/FrontFin/ios-sdk
```

or in a `Package.swift`:

```swift
.package(url: "https://github.com/FrontFin/ios-sdk.git", from: "0.1.0")
```

then add `MeshLink` to your target's dependencies.

## Get a session token

Mint a session token on **your backend** from `POST /v2/sessions` (it needs your
client secret, which must never ship in the app), send it to the app, and pass it
to the SDK together with your client ID.

## Usage (UIKit)

```swift
import MeshLink

let session = LinkSession(
    token: sessionToken,
    clientId: clientId,
    options: LinkOptions(environment: .prod, theme: .system, language: "en"),
    onExit: { summary in
        // summary.status is .success or .canceled
    },
    onError: { error in
        print(error.code) // .loadError / .loadTimeout / .sessionInterrupted
    }
)
session.present(from: viewController)
```

Storing `session` is optional: Link keeps it alive while it is on screen. Keep a
reference only if you want to close it from your app with `session.close()`.

If your app dismisses Link itself, or a screen below it (for example on logout),
the session ends with `onExit` and status `canceled`. A session is presented at
most once; create a new one, with a new token, to open Link again.

## Usage (SwiftUI)

```swift
struct DepositButton: View {
    let token: String
    let clientId: String
    @State private var showLink = false

    var body: some View {
        Button("Deposit") { showLink = true }
            .meshLink(
                isPresented: $showLink,
                token: token,
                clientId: clientId,
                options: LinkOptions(theme: .system),
                onExit: { _ in },
                onError: { _ in }
            )
    }
}
```

Link opens while `isPresented` is `true`; the SDK sets it back to `false` when the
session ends. Exactly one of `onExit` / `onError` fires per session, on the main
actor.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `environment` | `.prod` / `.sbx` / `.dev` | `.prod` | Which Link deployment to open. |
| `language` | `String?` | — | UI language, e.g. `"en"` (Link `lng`). |
| `theme` | `.light` / `.dark` / `.system` | — | `system` follows the device appearance, even if your app forces light or dark (`overrideUserInterfaceStyle`, `.preferredColorScheme`); pass `.light` / `.dark` to match a forced app appearance. |
| `integrationId` | `String?` | — | Pre-select a wallet or exchange. |
| `displayFiatCurrency` | `String?` | — | ISO 4217 code, e.g. `"DKK"`. A hint; Link validates it. |

A blank (empty or whitespace-only) `token` or `clientId` does not throw: when you
call `present`, the session ends at once with `onError` and code `.loadError`
(message `"token is required."` or `"clientId is required."`), and Link is not
shown.

## Session status

`success` means the user completed the target action (submitted a deposit or
transfer, finished a verify-only or connect-only flow, confirmed a withdrawal,
created a fiat ramp transfer). Anything else — including a session that ends with
no status — is `canceled`. Use it to drive your UI, **never as proof of payment**:
confirm the outcome server-side.

New statuses can be added in minor versions, so a `switch` over
`summary.status` needs a `default` branch.

## Errors

| `error.code` | Meaning |
| --- | --- |
| `.loadError` | The Link page failed to load, Link could not be presented, or `token` / `clientId` is blank. |
| `.loadTimeout` | The Link page did not finish loading within 15 s. |
| `.sessionInterrupted` | The WebView's content process stopped and the session cannot resume. |

`.loadTimeout` covers loading the Link page itself: it fires only if the page has
not finished loading after 15 s. A page that loads but never starts Link (for
example, its script fails) does not report an error; the native close button
appears instead, and closing it ends the session with `onExit` and status
`canceled`.

New error codes can be added in minor versions, so handle unknown ones:

```swift
switch error.code {
case .loadError, .loadTimeout:
    showRetry()
case .sessionInterrupted:
    showRestart()
default:
    showGenericError(error.code.rawValue)
}
```

## Wallet apps

Wallet deep links and external pages (OAuth, on-ramps) open in the wallet app or
the browser. Configure your app's own deep link / universal link so users can
return to it afterwards.

## Example app

[`Example/`](Example) is a SwiftUI app that wires up `.meshLink(...)`. It uses
[XcodeGen](https://github.com/yonaskolb/XcodeGen) — run `xcodegen generate` in
`Example/` to produce the Xcode project, then open and run it. Paste a client ID
and a session token to launch Link.

## Development

| Command | Does |
| --- | --- |
| `swift build` | Build the package. |
| `swift test` | Run the `Core` unit tests (URL, navigation, bridge, scripts) against the shared vectors. |
| `xcodebuild -scheme MeshLink -destination 'generic/platform=iOS Simulator' build` | Compile the full UIKit/SwiftUI surface. |

The URL and navigation test vectors in [`test-vectors/`](test-vectors) are shared
with the other Mesh mobile SDKs — keep them in sync.

### Versioning

The SDK version lives in both [`VERSION`](VERSION) and
[`Sources/MeshLink/Version.swift`](Sources/MeshLink/Version.swift); CI fails
when they disagree. Bump both with the `bump-version` skill
([`.claude/commands/bump-version.md`](.claude/commands/bump-version.md)). SPM
resolves git tags, so the GitHub Release (tag `X.Y.Z`) is the publication. There is
no release workflow yet: after the version-bump PR merges, push tag `X.Y.Z` on
`main` and create the GitHub Release by hand.

## License

[MIT](LICENSE)
