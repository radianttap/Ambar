// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ambar",
    platforms: [
		.iOS(.v15),
		.tvOS(.v15),
		.watchOS(.v10),
		.macOS(.v12),
		.visionOS(.v1)
    ],
    products: [
        .library(
            name: "Ambar",
            targets: ["Ambar"]
		),
    ],
    targets: [
        .target(
            name: "Ambar"
		)
	],
	swiftLanguageModes: [.v6]
)
