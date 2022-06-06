// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SolanaSwiftMagic",
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
    .package(url: "https://github.com/p2p-org/solana-swift", from: "2.0.1"),
  ],
  targets: [
    .target(
      name: "TransactionParser",
      dependencies: [
        .product(name: "SolanaSwift", package: "solana-swift"),
      ]
    ),
    .testTarget(
      name: "TransactionParserTests",
      dependencies: ["TransactionParser"],
      resources: [.process("./Resource")]
    ),
  ]
)

#if swift(>=5.6)
  // For generating docs purpose
  package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
