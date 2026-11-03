// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TeachablyCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "TeachablyCore", targets: ["TeachablyCore"])],
    targets: [
        .target(name: "TeachablyCore", resources: [.process("Resources")]),
        .testTarget(name: "TeachablyCoreTests", dependencies: ["TeachablyCore"])
    ]
)
