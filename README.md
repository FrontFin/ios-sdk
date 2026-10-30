# MeshPay Link iOS SDK

Open the hosted **MeshPay Link** UI full screen in an iOS app.

A thin native wrapper around `link.meshpay.com`: it builds the Link URL, shows it
in a `WKWebView`, speaks the Link bridge, routes wallet and OAuth hand-offs to the
OS, and reports exactly one outcome per session. **WebKit, UIKit and SwiftUI only
— no third-party dependencies.**

Distributed as `MeshpayLink` via Swift Package Manager.

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

then add `MeshpayLink` to your target's dependencies.

## Get a session token

Mint a session token on **your backend** from `POST /v2/sessions` (it needs your
client secret, which must never ship in the app), send it to the app, and pass it
to the SDK together with your client ID.

## Usage (UIKit)

```swift
import MeshpayLink

let session = try LinkSession(
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

Close it from your app with `session.close()`.

## Usage (SwiftUI)

```swift
struct DepositButton: View {
    let token: String
    let clientId: String
    @State private var showLink = false

    var body: some View {
        Button("Deposit") { showLink = true }
            .meshpayLink(
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
| `theme` | `.light` / `.dark` / `.system` | — | `system` follows the device appearance. |
| `integrationId` | `String?` | — | Pre-select a wallet or exchange. |
| `displayFiatCurrency` | `String?` | — | ISO 4217 code, e.g. `"DKK"`. A hint; Link validates it. |
| `linkUrl` | `String?` | — | **Testing only.** Load Link from a LocalCan tunnel (`https://*.localcan.dev`). Any other value is ignored. |

A blank `token` or `clientId` throws ``LinkConfigurationError`` from the
`LinkSession` initializer, so a misconfigured integration fails at call time.

## Session status

`success` means the user completed the target action (submitted a deposit or
transfer, finished a verify-only or connect-only flow, confirmed a withdrawal,
created a fiat ramp transfer). Anything else — including a session that ends with
no status — is `canceled`. Use it to drive your UI, **never as proof of payment**:
confirm the outcome server-side.

## Errors

| `error.code` | Meaning |
| --- | --- |
| `.loadError` | The Link page failed to load. |
| `.loadTimeout` | The Link page did not load within 15 s. |
| `.sessionInterrupted` | The WebView's content process stopped and the session cannot resume. |

## Wallet apps

Wallet deep links and external pages (OAuth, on-ramps) open in the wallet app or
the browser. Configure your app's own deep link / universal link so users can
return to it afterwards.

## Example app

[`Example/`](Example) is a SwiftUI app that wires up `.meshpayLink(...)`. It uses
[XcodeGen](https://github.com/yonaskolb/XcodeGen) — run `xcodegen generate` in
`Example/` to produce the Xcode project, then open and run it. Paste a client ID
and a session token to launch Link.

## Development

| Command | Does |
| --- | --- |
| `swift build` | Build the package. |
| `swift test` | Run the `Core` unit tests (URL, navigation, bridge, scripts) against the shared vectors. |
| `xcodebuild -scheme MeshpayLink -destination 'generic/platform=iOS Simulator' build` | Compile the full UIKit/SwiftUI surface. |

The URL and navigation test vectors in [`test-vectors/`](test-vectors) are shared
with the other MeshPay mobile SDKs — keep them in sync.

### Versioning

The SDK version lives in both [`VERSION`](VERSION) and
[`Sources/MeshpayLink/Version.swift`](Sources/MeshpayLink/Version.swift); CI fails
when they disagree. Bump both with the `bump-version` skill
([`.claude/commands/bump-version.md`](.claude/commands/bump-version.md)). SPM
resolves git tags, so the GitHub Release (tag `X.Y.Z`) is the publication — there
is no separate publish step.

## License

[MIT](LICENSE)
