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

    private let availableAssetsSubject: CurrentValueSubject<[SolendConfigAsset]?, Never> = .init([])
    public var availableAssets: AnyPublisher<[SolendConfigAsset]?, Never> { availableAssetsSubject.eraseToAnyPublisher()
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

        // Get config first and setup available assets
        if availableAssetsSubject.value == nil {
            do {
                let config: SolendConfig = try await solend.getConfig(environment: .production)
                let filteredAssets = config.assets.filter { allowedSymbols.contains($0.symbol) }
                availableAssetsSubject.send(filteredAssets)
            } catch {
                errorSubject.send(error)
                throw error
            }
        }

        // Get market in and user deposit
        let _ = await(
            try updateAvailableAssets(),
            try updateUserDeposits()
        )
    }

    private func updateAvailableAssets() async throws {
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
