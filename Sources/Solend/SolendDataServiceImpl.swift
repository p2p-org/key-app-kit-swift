// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import P2PSwift
import SolanaSwift

public class SolendDataServiceImpl: SolendDataService {
    private let solend: Solend
    private var owner: Account
    private var lendingMark: String
    private let allowedSymbols = ["SOL", "USDC", "USDT", "ETH", "BTC"]

    private let errorSubject: CurrentValueSubject<Error?, Never> = .init(nil)
    public var error: AnyPublisher<Error?, Never> { errorSubject.eraseToAnyPublisher() }

    private let statusSubject: CurrentValueSubject<SolendDataStatus, Never> = .init(.initialized)
    public var status: AnyPublisher<SolendDataStatus, Never> { statusSubject.eraseToAnyPublisher() }

    private let availableAssetsSubject: CurrentValueSubject<[SolendConfigAsset]?, Never> = .init(nil)
    public var availableAssets: AnyPublisher<[SolendConfigAsset]?, Never> {
        availableAssetsSubject.eraseToAnyPublisher()
    }

    private let depositsSubject: CurrentValueSubject<[SolendUserDeposit]?, Never> = .init([])
    public var deposits: AnyPublisher<[SolendUserDeposit]?, Never> { depositsSubject.eraseToAnyPublisher() }

    private let marketInfoSubject: CurrentValueSubject<[SolendMarketInfo]?, Never> = .init([])
    public var marketInfo: AnyPublisher<[SolendMarketInfo]?, Never> { marketInfoSubject.eraseToAnyPublisher() }

    public init(solend: Solend, owner: Account, lendingMark: String) {
        self.solend = solend
        self.owner = owner
        self.lendingMark = lendingMark

        Task.detached { try await self.update() }
    }

    public var hasDeposits: Bool {
        depositsSubject.value?.first { (Double($0.depositedAmount) ?? 0) > 0 } != nil
    }

    public func update() async throws {
        guard statusSubject.value != .updating else { return }

        // Setup status and clear error
        statusSubject.send(.updating)
        defer { statusSubject.send(.ready) }
        errorSubject.send(nil)

        // Update available assets and user deposits
        let _ = await(
            try updateConfig(),
            try updateUserDeposits()
        )

        // Update market info
        try await updateMarketInfo()
    }

    private func updateConfig() async throws {
        if availableAssetsSubject.value == nil {
            do {
                let config: SolendConfig = try await solend.getConfig(environment: .production)

                // Filter and fix usdt logo
                let filteredAssets = config.assets
                    .filter { allowedSymbols.contains($0.symbol) }
                    .map { asset -> SolendConfigAsset in
                        if asset.symbol == "USDT" {
                            return .init(
                                name: asset.name,
                                symbol: asset.symbol,
                                decimals: asset.decimals,
                                mintAddress: asset.mintAddress,
                                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4/logo.png"
                            )
                        }

                        return asset
                    }

                availableAssetsSubject.send(filteredAssets)
            } catch {
                errorSubject.send(error)
                throw error
            }
        }
    }

    private func updateMarketInfo() async throws {
        guard let availableAssets = availableAssetsSubject.value else {
            marketInfoSubject.send(nil)
            return
        }

        do {
            let marketInfo = try await solend
                .getMarketInfo(symbols: availableAssets.map(\.symbol), pool: "main")
                .map { token, marketInfo -> SolendMarketInfo in .init(
                    symbol: token,
                    currentSupply: marketInfo.currentSupply,
                    depositLimit: marketInfo.currentSupply,
                    supplyInterest: marketInfo.supplyInterest
                ) }
            marketInfoSubject.send(marketInfo)
        } catch {
            marketInfoSubject.send(nil)
            errorSubject.send(error)
            throw error
        }
    }

    private func updateUserDeposits() async throws {
        do {
            let userDeposits = try await solend.getUserDeposits(
                owner: owner.publicKey.base58EncodedString,
                poolAddress: lendingMark
            )
            depositsSubject.send(userDeposits)
        } catch {
            depositsSubject.send(nil)
            errorSubject.send(error)
            throw error
        }
    }
}
