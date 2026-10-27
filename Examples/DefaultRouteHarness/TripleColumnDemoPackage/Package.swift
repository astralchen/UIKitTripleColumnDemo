// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "TripleColumnDemoFeature",
    platforms: [.iOS(.v15)],
    products: [.library(name: "TripleColumnDemoFeature", targets: ["TripleColumnDemoFeature"])],
    dependencies: [.package(path: "../../..")],
    targets: [.target(name: "TripleColumnDemoFeature", dependencies: [.product(name: "RouteModel", package: "UIKitTripleColumnDemo")])]
)
