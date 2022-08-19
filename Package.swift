// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyAppKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),

    ],
    products: [
        .library(name: "Cache", targets: ["Cache"]),
        
        .library(
            name: "KeyAppKitLogger",
            targets: ["KeyAppKitLogger"]
        ),
        .library(
            name: "TransactionParser",
            targets: ["TransactionParser"]
        ),
        
        .library(
            name: "NameService",
            targets: ["NameService"]
        ),
        
        // Analytics manager for wallet
        .library(
            name: "AnalyticsManager",
            targets: ["AnalyticsManager"]
        ),
        
        // Price service for wallet
        .library(
            name: "SolanaPricesAPIs",
            targets: ["SolanaPricesAPIs"]
        ),
        
        // JSBridge
        .library(
            name: "JSBridge",
            targets: ["JSBridge"]
        ),
        
        // Countries
        .library(
            name: "CountriesAPI",
            targets: ["CountriesAPI"]
        ),
        
        // Tkey
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/solana-swift", from: "2.1.1"),
        .package(url: "https://github.com/amplitude/Amplitude-iOS", from: "8.3.0"),
        .package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", from: "1.0.2"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.5.1"))
    ],
    targets: [
        // Cache
        .target(name: "Cache"),
        
        // KeyAppKitLogger
        .target(name: "KeyAppKitLogger"),
        
        // Transaction Parser
        .target(
            name: "TransactionParser",
            dependencies: [
                "Cache",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "TransactionParserUnitTests",
            dependencies: ["TransactionParser"],
            path: "Tests/UnitTests/TransactionParserUnitTests",
            resources: [.process("./Resource")]
        ),

        // Name Service
        .target(
            name: "NameService",
            dependencies: ["KeyAppKitLogger"]
        ),
        .testTarget(
            name: "NameServiceIntegrationTests",
            dependencies: [
                "NameService",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ],
            path: "Tests/IntegrationTests/NameServiceIntegrationTests"
        ),

        // AnalyticsManager
        .target(
            name: "AnalyticsManager",
            dependencies: [.product(name: "Amplitude", package: "Amplitude-iOS")]
        ),
        .testTarget(
            name: "AnalyticsManagerUnitTests",
            dependencies: ["AnalyticsManager"],
            path: "Tests/UnitTests/AnalyticsManagerUnitTests"
        ),

        // PricesService
        .target(
            name: "SolanaPricesAPIs",
            dependencies: ["Cache", .product(name: "SolanaSwift", package: "solana-swift")]
        ),
        .testTarget(
            name: "SolanaPricesAPIsUnitTests",
            dependencies: ["SolanaPricesAPIs"],
            path: "Tests/UnitTests/SolanaPricesAPIsUnitTests"
            //      resources: [.process("./Resource")]
        ),

        // JSBridge
        .target(
            name: "JSBridge"
        ),
        .testTarget(name: "JSBridgeTests", dependencies: ["JSBridge"]),
        
        // Countries
        .target(
            name: "CountriesAPI",
            resources: [
                .process("Resources/countries.json")
            ]
        ),
        .testTarget(
            name: "CountriesAPIUnitTests",
            dependencies: ["CountriesAPI"],
            path: "Tests/UnitTests/CountriesAPIUnitTests"
            //      resources: [.process("./Resource")]
        ),

        // TKey
        .target(
            name: "Onboarding",
            dependencies: [
                "JSBridge",
                .product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                
            ],
            resources: [
                .process("Resource/bundle.js.map"),
                .process("Resource/index.html")
            ]
        ),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"])
    ]
)

#if swift(>=5.6)
    // For generating docs purpose
    package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
