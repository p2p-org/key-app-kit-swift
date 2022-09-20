// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias SolanaRawTransaction = String
public typealias SolendSymbol = String

public enum SolendEnvironment: String {
    case production
    case devnet
}

public struct SolendCollateralAccount: Codable {
    public let address: String
    public let mint: String
}

public struct SolendMarketInfo: Codable {
    public let currentSupply, depositLimit, supplyInterest: String

    enum CodingKeys: String, CodingKey {
        case currentSupply = "current_supply"
        case depositLimit = "deposit_limit"
        case supplyInterest = "supply_interest"
    }
}

public struct SolendUserDeposit: Codable {
    public let symbol: String
    public let depositedAmount: String
}

public struct SolendDepositFee: Codable {
    public let fee: UInt64
    public let rent: UInt64
}

public struct SolendPayFeeInToken: Codable {
    public let senderAccount: String
    public let recipientAccount: String
    public let mint: String
    public let authority: String
    public let exchangeRate: Float64
    public let decimals: UInt8

    enum CodingKeys: String, CodingKey {
        case senderAccount = "sender_account_pubkey"
        case recipientAccount = "recipient_account_pubkey"
        case mint = "mint_pubkey"
        case authority = "authority_pubkey"
        case exchangeRate = "exchange_rate"
        case decimals
    }

    public init(
        senderAccount: String,
        recipientAccount: String,
        mint: String,
        authority: String,
        exchangeRate: Float64,
        decimals: UInt8
    ) {
        self.senderAccount = senderAccount
        self.recipientAccount = recipientAccount
        self.mint = mint
        self.authority = authority
        self.exchangeRate = exchangeRate
        self.decimals = decimals
    }
}
