// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

// MARK: - Quote
public struct Route: Codable, Equatable {
    public let inAmount, outAmount: String
    public let priceImpactPct: Double
    public let marketInfos: [MarketInfo]
    public let amount: String
    public let slippageBps: Int
    public let otherAmountThreshold, swapMode: String

    public init(
        inAmount: String,
        outAmount: String,
        priceImpactPct: Double,
        marketInfos: [MarketInfo],
        amount: String,
        slippageBps: Int,
        otherAmountThreshold: String,
        swapMode: String
    ) {
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.priceImpactPct = priceImpactPct
        self.marketInfos = marketInfos
        self.amount = amount
        self.slippageBps = slippageBps
        self.otherAmountThreshold = otherAmountThreshold
        self.swapMode = swapMode
    }
}

// MARK: - MarketInfo

public struct MarketInfo: Codable, Equatable {
    public let id, label: String
    public let inputMint, outputMint: String
    public let notEnoughLiquidity: Bool
    public let inAmount, outAmount: String
    public let priceImpactPct: Double
    public let lpFee, platformFee: Fee

    public init(
        id: String,
        label: String,
        inputMint: String,
        outputMint: String,
        notEnoughLiquidity: Bool,
        inAmount: String,
        outAmount: String,
        priceImpactPct: Double,
        lpFee: Fee,
        platformFee: Fee
    ) {
        self.id = id
        self.label = label
        self.inputMint = inputMint
        self.outputMint = outputMint
        self.notEnoughLiquidity = notEnoughLiquidity
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.priceImpactPct = priceImpactPct
        self.lpFee = lpFee
        self.platformFee = platformFee
    }
}


// MARK: - Fee

public struct Fee: Codable, Equatable {
    public let amount: String
    public let mint: String
    public let pct: Double

    public init(amount: String, mint: String, pct: Double) {
        self.amount = amount
        self.mint = mint
        self.pct = pct
    }
}
