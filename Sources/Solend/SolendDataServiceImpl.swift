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

    private let statusSubject: CurrentValueSubject<SolendDataStatus, Never> = .init(.initialized)
    public var status: AnyPublisher<SolendDataStatus, Never>

    public let availableAssetsSubject: CurrentValueSubject<[SolendConfigAsset], Never> = .init([])
    public var availableAssets: AnyPublisher<[SolendConfigAsset], Never> { availableAssetsSubject.eraseToAnyPublisher()
    }

    public let depositsSubject: CurrentValueSubject<[SolendUserDeposit], Never> = .init([])
    public var deposits: AnyPublisher<[SolendUserDeposit], Never> { depositsSubject.eraseToAnyPublisher() }

    public let marketInfoSubject: CurrentValueSubject<[SolendMarketInfo], Never> = .init([])
    public var marketInfo: AnyPublisher<[SolendMarketInfo], Never> { marketInfoSubject.eraseToAnyPublisher() }

    public init(solend: Solend, owner: Account, lendingMark: String) {
        self.solend = solend
        self.owner = owner
        self.lendingMark = lendingMark
    }

    public var hasDeposits: Bool {
        depositsSubject.value.first { (Double($0.depositedAmount) ?? 0) > 0 } != nil
    }

    public func update() async throws {
        guard statusSubject.value != .updating else { return }

        do {
            statusSubject.send(.updating)
            defer { statusSubject.send(.ready) }

            // Get config first
            if availableAssetsSubject.value.isEmpty {
                let config: SolendConfig = try await solend.getConfig(environment: .production)
                let filteredAssets = config.assets.filter { allowedSymbols.contains($0.symbol) }
                availableAssetsSubject.send(filteredAssets)
            }

            // Get market in and user deposit
            await updateValues(
                marketInfo: try? solend
                    .getMarketInfo(symbols: availableAssetsSubject.value.map(\.symbol), pool: "main")
                    .map { token, marketInfo -> SolendMarketInfo in .init(
                        symbol: token,
                        currentSupply: marketInfo.currentSupply,
                        depositLimit: marketInfo.currentSupply,
                        supplyInterest: marketInfo.supplyInterest
                    ) },
                deposits: try? solend.getUserDeposits(
                    owner: owner.publicKey.base58EncodedString,
                    poolAddress: lendingMark
                )
            )
        } catch {
            throw error
        }
    }

    public func updateValues(
        marketInfo: [SolendMarketInfo]?,
        deposits: [SolendUserDeposit]?
    ) {
        depositsSubject.send(deposits ?? [])
        marketInfoSubject.send(marketInfo ?? [])
    }
}
