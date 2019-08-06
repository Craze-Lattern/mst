// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mst",
	products: [
		.library(name: "MstKit", targets: ["MstKit"]),
		.executable(name: "mst", targets: ["mst"])
	],
    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.16.0"),
		.package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
		.package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
		.package(url: "https://github.com/JohnSundell/Files", from: "3.1.0")
    ],
    targets: [
		.target(
			name: "MstKit",
			dependencies: ["Rainbow", "Files"]
		),
        .target(
            name: "mst",
            dependencies: ["MstKit", "Commandant", "Curry", "Rainbow"])
    ],
	swiftLanguageVersions: [.v4_2, .v5]
)
