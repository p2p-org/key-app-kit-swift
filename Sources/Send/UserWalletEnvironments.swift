// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaPricesAPIs
import SolanaSwift

public struct UserWalletEnvironments: Equatable {
    let wallets: [Wallet]
    let exchangeRate: [String: CurrentPrice]
    let tokens: Set<Token>

    let rentExemptionAmountForWalletAccount: Lamports
    let rentExemptionAmountForSPLAccount: Lamports

    public init(
        wallets: [Wallet],
        exchangeRate: [String: CurrentPrice],
        tokens: Set<Token>,
        rentExemptionAmountForWalletAccount: Lamports = 890_880,
        rentExemptionAmountForSPLAccount: Lamports = 2_039_280
    ) {
        self.wallets = wallets
        self.exchangeRate = exchangeRate
        self.tokens = tokens
        self.rentExemptionAmountForWalletAccount = rentExemptionAmountForWalletAccount
        self.rentExemptionAmountForSPLAccount = rentExemptionAmountForSPLAccount
    }

    public static var empty: Self {
        .init(wallets: [], exchangeRate: [:], tokens: [])
    }

    public func copy(tokens: Set<Token>? = nil) -> Self {
        .init(
            wallets: wallets,
            exchangeRate: exchangeRate,
            tokens: tokens ?? self.tokens,
            rentExemptionAmountForWalletAccount: rentExemptionAmountForWalletAccount,
            rentExemptionAmountForSPLAccount: rentExemptionAmountForSPLAccount
        )
    }
}

extension UserWalletEnvironments {
    func amountInFiat(_ tokenSymbol: String, _ amount: Double?) -> Double {
        (exchangeRate[tokenSymbol]?.value ?? 0.0) * (amount ?? 0.0)
    }
}
