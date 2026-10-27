// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "RouteModel",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "RouteModel", targets: ["RouteModel"])],
    targets: [.target(name: "RouteModel"), .testTarget(name: "RouteModelTests", dependencies: ["RouteModel"])]
)
