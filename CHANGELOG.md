# Changelog

All notable changes to the Mesh Link iOS SDK are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0

### Changed
- First stable release. The public API (`LinkSession`, the `.meshLink(...)` view modifier, `LinkOptions` and the exported types) now follows Semantic Versioning: breaking changes ship only in a new major version.
- `LinkErrorCode` and `LinkExitStatus` may gain new values in minor releases. Handle unknown values, for example with a `default` branch.
- Renamed the package, product and module from `MeshpayLink` to `MeshLink` (`import MeshLink`), and the view modifier from `.meshpayLink(...)` to `.meshLink(...)`.
- `onExit` and `onError` are now typed `@MainActor`, matching the main-actor delivery the SDK already guaranteed.
- The native close button appears after 2s instead of 3s and matches the React Native SDK.

### Added
- `MeshLinkSDK.version`, the SDK version string.
- Initial loading enhancements: a loading spinner appears after 1s.

### Fixed
- `theme: .system` follows the device appearance even when the host app forces light or dark.
- Native UI inside Link (loading spinner, close button, keyboard) follows Link's resolved theme instead of the host app's appearance.

## 0.1.0

### Added
- `LinkSession` that opens the hosted Mesh Link UI full screen in a `WKWebView`, with `onExit(LinkExitSummary)` and `onError(LinkError)` callbacks and exactly one outcome per session
- SwiftUI `.meshLink(isPresented:token:clientId:options:onExit:onError:)` view modifier
- `LinkOptions` for environment, language, theme, pre-selected integration and display fiat currency
- Host-initiated close through `LinkSession.close()`, reporting the status Link returns
- Navigation policy that opens wallet deep links and external pages (OAuth, on-ramps) in the wallet app or browser and blocks unsafe schemes
- Privacy manifest (`PrivacyInfo.xcprivacy`): no tracking, no required-reason APIs
