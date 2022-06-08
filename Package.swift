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
    // TransactionParser to parse type of transactions in Solana Blockchain
    .library(
      name: "TransactionParser",
      targets: ["TransactionParser"]
    ),
    // Name service manages unique, decentralized user name on Solana Blockchain
    .library(
      name: "NameService",
      targets: ["NameService"]
    ),
    // Fee relayer is the service that helps customizing fee payer on Transaction in Solana Blockchain
    .library(
      name: "FeeRelayer",
      targets: ["FeeRelayer"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/p2p-org/solana-swift", from: "2.0.1"),
  ],
  targets: [
    // TransactionParser
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
    // NameService
    .target(
      name: "NameService",
      dependencies: []
    ),
    
    // FeeRelayer
    .binaryTarget(
      name: "FeeRelayerBinary",
      path: "Sources/FeeRelayer/Binary/FeeRelayerBinary.xcframework"
    ),
    .target(
      name: "FeeRelayer",
      dependencies: ["FeeRelayerBinary"],
      path: "Sources/FeeRelayer/Bridge"
    ),
    .testTarget(
      name: "FeeRelayerTests",
      dependencies: ["FeeRelayer"]
//      resources: [.process("./Resource")]
    ),
  ]
)

#if swift(>=5.6)
  // For generating docs purpose
  package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
