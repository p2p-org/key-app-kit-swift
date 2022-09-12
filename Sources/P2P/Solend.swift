// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol Solend {
    func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [SolendCollateralAccount]

    /// Fetch market info
    ///
    /// - Parameters:
    ///   - tokens: Token symbol. Example: USDT, USDC, SOL
    ///   - pool: Solend pool. Example: main
    func getMarketInfo(tokens: [String], pool: String) async throws -> [(token: String, marketInfo: SolendMarketInfo)]

    /// Fetch user deposit
    ///
    /// - Parameters:
    ///   - owner: wallet address
    ///   - poolAddress:
    func getUserDeposits(owner: String, poolAddress: String) async throws -> [SolendUserDeposit]

    func getUserDepositBySymbol(owner: String, symbol: String, poolAddress: String) async throws -> SolendUserDeposit
}
