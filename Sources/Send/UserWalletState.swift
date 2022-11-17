// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import SolanaPricesAPIs

public struct UserWalletState: Equatable {
    let wallets: [Wallet]
    let exchangeRate: [String: CurrentPrice]
    
    public init(wallets: [Wallet], exchangeRate: [String: CurrentPrice]) {
        self.wallets = wallets
        self.exchangeRate = exchangeRate
    }
}
