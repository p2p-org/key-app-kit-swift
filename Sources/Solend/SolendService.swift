// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import P2PSwift
import SolanaSwift

public struct SolendMarketInfo: Codable {
    public let symbol: String
    public let currentSupply: String
    public let depositLimit: String
    public let supplyInterest: String
}

protocol SolendService {}

class SolendServiceImpl: SolendService {
    private let solend: Solend = SolendFFIWrapper()

    private var owner: Account
    private var lendingMark: String

    let availableSymbols: CurrentValueSubject<[SolendSymbol]> = .init(["SOL", "USDT", "USDC", "BTC", "ETH"])
    let deposits: CurrentValueSubject<[SolendUserDeposit]> = .init([])
    let marketInfo: CurrentValueSubject<[SolendMarketInfo]> = .init([])

    init(owner: Account) {
        self.owner = owner
    }

    var hasDeposits: Bool {
        deposits.value.first { Double($0.depositedAmount) > 0 } != nil
    }

    func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [SolendCollateralAccount] {
        try await solend.getCollateralAccounts(rpcURL: rpcURL, owner: owner)
    }

    func updateStatus() async throws {
        async let marketInfo: [SolendMarketInfo] = try solend
            .getMarketInfo(symbols: availableSymbols.value, pool: "main")
            .map { token, marketInfo -> SolendMarketInfo in .init(
                symbol: token,
                currentSupply: marketInfo.currentSupply,
                depositLimit: marketInfo.currentSupply,
                supplyInterest: marketInfo.supplyInterest
            ) }

        async let deposits: [SolendUserDeposit] = try await solend.getUserDeposits(
            owner: owner.publicKey.base58EncodedString,
            poolAddress: lendingMark
        )

        try await {
            try self.deposits.send(deposits)
            try self.marketInfo.send(marketInfo)
        }
    }
}
