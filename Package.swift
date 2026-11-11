// swift-tools-version: 6.0
// MeshLink — the Mesh Link iOS SDK.
//
// A thin native wrapper that opens the hosted Mesh Link UI full screen in a
// WKWebView. WebKit, UIKit and SwiftUI only — no third-party dependencies.

import PackageDescription

let package = Package(
    name: "MeshLink",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MeshLink",
            targets: ["MeshLink"]
        )
    ],
    targets: [
        .target(
            name: "MeshLink",
            path: "Sources/MeshLink",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MeshLinkTests",
            dependencies: ["MeshLink"],
            path: "Tests/MeshLinkTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
