// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "P2PSolanaSwiftLibrary",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),

  ],
  products: [
    .library(
      name: "TransactionParser",
      targets: ["TransactionParser"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/p2p-org/solana-swift", branch: "refactor/fix-protection-level"),
//     .package(path: "/Users/longtran/workspace/p2p/p2p-wallet-ios/SolanaSwift"),
    // .package(url: "https://github.com/p2p-org/OrcaSwapSwift", branch: "main"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "TransactionParser",
      dependencies: [
        .product(name: "SolanaSwift", package: "solana-swift"),
        // .product(name: "OrcaSwapSwift", package: "OrcaSwapSwift"),
      ]
    ),
    .testTarget(
      name: "TransactionParserTests",
      dependencies: ["TransactionParser"],
      resources: [.process("./Resource")]
    ),
  ]
)
