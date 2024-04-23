// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ambar",
    platforms: [
		.iOS(.v15),
		.tvOS(.v15),
		.watchOS(.v10),
		.macOS(.v10_15),
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
            name: "Ambar",
			dependencies: [],
            path: "Ambar"
		)
	]
)
