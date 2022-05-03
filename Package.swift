// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "CardFan",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(
            name: "CardFan",
            targets: ["CardFan"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CardFan"
        )
    ]
)
