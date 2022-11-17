// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum Amount: Equatable {
    case fiat(value: Double, currency: String)
    case token(lamport: UInt64, mint: String, decimals: Int)
}

public enum SendInputAction: Equatable {
    case changeAmountInFiat(Double)
    case changeAmountInToken(Double)
    case changeUserToken(Wallet)
}

public struct SendInputState: Equatable {
    public enum ErrorReason: Equatable {
        case networkConnectionError(NSError)
        case minimumAmount(Amount)
    }

    public enum Status: Equatable {
        case processing
        case ready
        case error(reason: ErrorReason)
    }
    
    let status: Status
    
    let recipient: Recipient
    let userTokenAccount: Wallet
    let userWalletState: UserWalletState

    let amountInFiat: Double
    let amountInToken: Double

    let fee: FeeAmount
    
    public init(
        status: Status,
        recipient: Recipient,
        userTokenAccount: Wallet,
        userWalletState: UserWalletState,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount
    ) {
        self.status = status
        self.recipient = recipient
        self.userTokenAccount = userTokenAccount
        self.userWalletState = userWalletState
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.fee = fee
    }
}
