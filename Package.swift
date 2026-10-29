// swift-tools-version: 6.0
// MeshpayLink — the MeshPay Link iOS SDK.
//
// A thin native wrapper that opens the hosted MeshPay Link UI full screen in a
// WKWebView. WebKit, UIKit and SwiftUI only — no third-party dependencies.

import PackageDescription

let package = Package(
    name: "MeshpayLink",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MeshpayLink",
            targets: ["MeshpayLink"]
        )
    ],
    targets: [
        .target(
            name: "MeshpayLink",
            path: "Sources/MeshpayLink",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MeshpayLinkTests",
            dependencies: ["MeshpayLink"],
            path: "Tests/MeshpayLinkTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
