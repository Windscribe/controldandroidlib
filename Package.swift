// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Ctrld",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Ctrld",
            targets: ["Ctrld"]
        ),
    ],
    targets: [
        .target(name: "Ctrld"),
        		.binaryTarget(
        			name: "CtrldLib",
        			path: "Sources/Ctrld.xcframework"
        		),
    ]
)