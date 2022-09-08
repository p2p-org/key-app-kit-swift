// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct ReserveApiModel {
    // MARK: - Reserve

    struct Reserve: Codable {
        let reserve: ReserveClass
        let cTokenExchangeRate: String
        let rates: Rates
        let rewards: [Reward]
    }

    // MARK: - Rates

    struct Rates: Codable {
        let supplyInterest, borrowInterest: String
    }

    // MARK: - ReserveClass

    struct ReserveClass: Codable {
        let version: Int
        let lastUpdate: LastUpdate
        let lendingMarket: String
        let liquidity: Liquidity
        let collateral: Collateral
        let config: Config
    }

    // MARK: - Collateral

    struct Collateral: Codable {
        let mintPubkey, mintTotalSupply, supplyPubkey: String
    }

    // MARK: - Config

    struct Config: Codable {
        let optimalUtilizationRate, loanToValueRatio, liquidationBonus, liquidationThreshold: Int
        let minBorrowRate, optimalBorrowRate, maxBorrowRate: Int
        let fees: Fees
        let depositLimit, borrowLimit, feeReceiver: String
        let protocolLiquidationFee, protocolTakeRate: Int
        let accumulatedProtocolFeesWads: String
    }

    // MARK: - Fees

    struct Fees: Codable {
        let borrowFeeWad, flashLoanFeeWad: String
        let hostFeePercentage: Int
    }

    // MARK: - LastUpdate

    struct LastUpdate: Codable {
        let slot: String
        let stale: Int
    }

    // MARK: - Liquidity

    struct Liquidity: Codable {
        let mintPubkey: String
        let mintDecimals: Int
        let supplyPubkey, pythOracle, switchboardOracle, availableAmount: String
        let borrowedAmountWads, cumulativeBorrowRateWads, marketPrice: String
    }

    // MARK: - Reward

    struct Reward: Codable {
        let rewardMint, rewardSymbol, apy, side: String
    }
}
