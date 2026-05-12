// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SharedOpenBankingKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HSBCOpenBankingChat",
            targets: ["SharedOpenBankingKit"]
        ),
        .library(
            name: "SharedOpenBankingKit",
            targets: ["SharedOpenBankingKit"]
        )
    ],
    targets: [
        .target(
            name: "SharedOpenBankingKit"
        ),
        .testTarget(
            name: "SharedOpenBankingKitTests",
            dependencies: ["SharedOpenBankingKit"]
        )
    ]
)
