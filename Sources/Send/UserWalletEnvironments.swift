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
    
    public init(wallets: [Wallet], exchangeRate: [String: CurrentPrice], tokens: Set<Token>) {
        self.wallets = wallets
        self.exchangeRate = exchangeRate
        self.tokens = tokens
    }
}
