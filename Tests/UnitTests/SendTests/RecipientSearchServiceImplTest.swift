// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import SolanaSwift
import XCTest
@testable import Send

class RecipientSearchServiceImplTest: XCTestCase {
    let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
        wallets: [
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                lamports: 5_000_000,
                token: .nativeSolana
            ),
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh22",
                lamports: 5_000_000,
                token: .usdc
            ),
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh23",
                lamports: 5_000_000,
                token: .usdt
            ),
        ],
        exchangeRate: [:],
        tokens: [.nativeSolana, .usdc, .usdt]
    )

    let defaultSolanaClient: SolanaAPIClient = JSONRPCAPIClient(
        endpoint: .init(
            address: "https://api.mainnet-beta.solana.com",
            network: .mainnetBeta
        )
    )

    func testOkTests() async throws {
        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(input: "kirill", env: defaultInitialWalletEnvs)
        XCTAssertEqual(result, .ok([]))
    }

    func testSolanaAddress() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
                if account == "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM" {
                    return BufferInfo<SmartInfo>(
                        lamports: 12000,
                        owner: SystemProgram.id.base58EncodedString,
                        data: .empty,
                        executable: false,
                        rentEpoch: 361
                    ) as? BufferInfo<T>
                } else {
                    return nil
                }
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(result, .ok([
            .init(
                address: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
                category: .solanaAddress,
                attributes: [.funds]
            ),
        ]))
    }

    func testSolanaAddressNotFound() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(result, .ok([
            .init(
                address: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
                category: .solanaAddress,
                attributes: []
            ),
        ]))
    }

    func testSolanaTokenAddress() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
                if account == "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU" {
                    return BufferInfo<SmartInfo>(
                        lamports: 5000,
                        owner: SystemProgram.id.base58EncodedString,
                        data: .splAccount(
                            .init(
                                mint: try PublicKey(string: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"),
                                owner: try PublicKey(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                                lamports: 1579,
                                delegateOption: 0,
                                isInitialized: false,
                                isFrozen: false,
                                state: 0,
                                isNativeOption: 0,
                                isNativeRaw: 0,
                                isNative: false,
                                delegatedAmount: 0,
                                closeAuthorityOption: 0
                            )
                        ),
                        executable: false,
                        rentEpoch: 361
                    ) as? BufferInfo<T>
                } else {
                    return nil
                }
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
            env: defaultInitialWalletEnvs
        )
        XCTAssertEqual(
            result,
            .ok([
                .init(
                    address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                    category: .solanaTokenAddress(
                        walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                        token: .usdc
                    ),
                    attributes: [.funds, .pda]
                ),
            ])
        )
    }

    func testSolanaTokenAddressAndMissingUserToken() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
                if account == "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU" {
                    return BufferInfo<SmartInfo>(
                        lamports: 5000,
                        owner: SystemProgram.id.base58EncodedString,
                        data: .splAccount(
                            .init(
                                mint: try PublicKey(string: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"),
                                owner: try PublicKey(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                                lamports: 1579,
                                delegateOption: 0,
                                isInitialized: false,
                                isFrozen: false,
                                state: 0,
                                isNativeOption: 0,
                                isNativeRaw: 0,
                                isNative: false,
                                delegatedAmount: 0,
                                closeAuthorityOption: 0
                            )
                        ),
                        executable: false,
                        rentEpoch: 361
                    ) as? BufferInfo<T>
                } else {
                    return nil
                }
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
            wallets: [
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                    lamports: 5_000_000,
                    token: .nativeSolana
                ),
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh23",
                    lamports: 5_000_000,
                    token: .usdt
                ),
            ],
            exchangeRate: [:],
            tokens: [.nativeSolana, .usdc, .usdt]
        )

        let result = await service.search(
            input: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
            env: defaultInitialWalletEnvs
        )
        XCTAssertEqual(
            result,
            .missingUserToken(recipient: .init(
                address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                category: .solanaTokenAddress(
                    walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                    token: .usdc
                ),
                attributes: [.funds, .pda]
            ))
        )
    }

    func testSolanaTokenAddressAndUserTokenBalanceZero() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
                if account == "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU" {
                    return BufferInfo<SmartInfo>(
                        lamports: 5000,
                        owner: SystemProgram.id.base58EncodedString,
                        data: .splAccount(
                            .init(
                                mint: try PublicKey(string: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"),
                                owner: try PublicKey(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                                lamports: 1579,
                                delegateOption: 0,
                                isInitialized: false,
                                isFrozen: false,
                                state: 0,
                                isNativeOption: 0,
                                isNativeRaw: 0,
                                isNative: false,
                                delegatedAmount: 0,
                                closeAuthorityOption: 0
                            )
                        ),
                        executable: false,
                        rentEpoch: 361
                    ) as? BufferInfo<T>
                } else {
                    return nil
                }
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
            wallets: [
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                    lamports: 5_000_000,
                    token: .nativeSolana
                ),
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                    lamports: 0,
                    token: .usdc
                ),
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh23",
                    lamports: 5_000_000,
                    token: .usdt
                ),
            ],
            exchangeRate: [:],
            tokens: [.nativeSolana, .usdc, .usdt]
        )

        let result = await service.search(
            input: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
            env: defaultInitialWalletEnvs
        )
        XCTAssertEqual(
            result,
            .missingUserToken(recipient: .init(
                address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                category: .solanaTokenAddress(
                    walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                    token: .usdc
                ),
                attributes: [.funds, .pda]
            ))
        )
    }

    func testSolanaTokenAddressNotExits() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
            env: defaultInitialWalletEnvs
        )
        XCTAssertEqual(
            result,
            .ok([
                .init(
                    address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                    category: .solanaAddress,
                    attributes: [.pda]
                ),
            ])
        )
    }

    func testInvalidLongInputTests() async throws {
        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "epstein didn’t kill himself",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(result, .ok([]))
    }

    func testInvalidShort1SymbolInputTests() async throws {
        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(input: "e", env: defaultInitialWalletEnvs)
        XCTAssertEqual(result, .ok([]))
    }

    func testInvalidShort2SymbolsInputTests() async throws {
        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(input: "ea", env: defaultInitialWalletEnvs)
        XCTAssertEqual(result, .ok([]))
    }

    func testNameService() async throws {
        class TestMockNameService: MockedNameService {
            override func getOwners(_: String) async throws -> [NameRecord] {
                [
                    .init(
                        name: "kirill.key",
                        parent: "6vQGsE2pqtnKbeWWESzGtYT5BRCQUmaB7Lq8vw4AuHG6",
                        owner: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                    .init(
                        name: "kirill.p2p.sol",
                        parent: "HSqVcxpDaZzwkHxreLisDtR9bQsLaTCMzMATFVhDoeNe",
                        owner: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                ]
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: TestMockNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "kirill",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(result, .ok([
            .init(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill", domain: "key"),
                attributes: []
            ),
            .init(
                address: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                category: .username(name: "kirill.p2p", domain: "sol"),
                attributes: []
            ),
        ]))
    }

    func testNameServiceError() async throws {
        class TestMockNameService: MockedNameService {
            static let error = NSError(domain: "Network", code: 404)

            override func getOwners(_: String) async throws -> [NameRecord] {
                throw Self.error
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: TestMockNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "kirill",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(result, .nameServiceError(TestMockNameService.error))
    }

    // func testNoRenBTCError() async throws {
    //     let service = RecipientSearchServiceImpl(nameService: MockedNameService())
    //
    //     let result = try await service.search(
    //         input: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
    //         state: userWalletState
    //     )
    //     expectResult(.notEnoughRenBTC, result)
    // }

    func testInsufficientUserFundsOnlySOL() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: .init(transaction: 0, accountBalances: 890_880))
        )

        let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
            wallets: [
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                    lamports: 1000,
                    token: .nativeSolana
                ),
            ],
            exchangeRate: [:],
            tokens: [.nativeSolana, .usdc, .usdt]
        )

        let result = await service.search(
            input: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(
            result,
            .insufficientUserFunds(recipient: .init(
                address: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
                category: .solanaAddress,
                attributes: [.pda]
            ))
        )
    }

    func testInsufficientUserFundsOnlyTokens() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }
        }

        let service = RecipientSearchServiceImpl(
            nameService: MockedNameService(),
            solanaClient: SolanaAPIClient(),
            swapService: MockedSwapService(result: .init(transaction: 0, accountBalances: 1_000_000))
        )

        let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
            wallets: [
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh20",
                    lamports: 1000,
                    token: .usdt
                ),
                Wallet(
                    pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                    lamports: 1000,
                    token: .usdc
                ),
            ],
            exchangeRate: [:],
            tokens: [.nativeSolana, .usdc, .usdt]
        )

        let result = await service.search(
            input: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
            env: defaultInitialWalletEnvs
        )

        XCTAssertEqual(
            result,
            .insufficientUserFunds(recipient: .init(
                address: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
                category: .solanaAddress,
                attributes: [.pda]
            ))
        )
    }
}
