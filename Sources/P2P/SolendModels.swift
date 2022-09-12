// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct SolendCollateralAccount: Codable {
    public let address: String
    public let mint: String
}

public struct SolendMarketInfo: Codable {
    let currentSupply, depositLimit, supplyInterest: String

    enum CodingKeys: String, CodingKey {
        case currentSupply = "current_supply"
        case depositLimit = "deposit_limit"
        case supplyInterest = "supply_interest"
    }
}

public struct SolendUserDeposit: Codable {
    let symbol: String
    let depositedAmount: String
}
