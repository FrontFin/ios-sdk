# Changelog

All notable changes to the MeshPay Link iOS SDK are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0

### Added
- `LinkSession` that opens the hosted MeshPay Link UI full screen in a `WKWebView`, with `onExit(LinkExitSummary)` and `onError(LinkError)` callbacks and exactly one outcome per session
- SwiftUI `.meshpayLink(isPresented:token:clientId:options:onExit:onError:)` view modifier
- `LinkOptions` for environment, language, theme, pre-selected integration and display fiat currency
- Host-initiated close through `LinkSession.close()`, reporting the status Link returns
- Navigation policy that opens wallet deep links and external pages (OAuth, on-ramps) in the wallet app or browser and blocks unsafe schemes
- Privacy manifest (`PrivacyInfo.xcprivacy`): no tracking, no required-reason APIs
