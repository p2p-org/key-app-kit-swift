// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public struct Recipient: Hashable, Equatable {
    public enum Category: Hashable, Equatable {
        case username(name: String, domain: String)
        
        case solanaAddress
        case solanaTokenAddress(walletAddress: PublicKey, mintAddress: PublicKey)
        
        case bitcoinAddress
    }

    public init(address: String, category: Category, hasFunds: Bool) {
        self.address = address
        self.category = category
        self.hasFunds = hasFunds
    }

    public let address: String
    public let category: Category
    public let hasFunds: Bool
}
