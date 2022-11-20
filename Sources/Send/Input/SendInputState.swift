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

public struct SendInputServices {
    let swapService: SwapService
}

public struct SendInputState: Equatable {
    public enum ErrorReason: Equatable {
        case networkConnectionError(NSError)
        case minimumAmount(Amount)
        case inputTooHigh
        case inputTooLow
    }

    public enum Status: Equatable {
        case processing
        case ready
        case error(reason: ErrorReason)
    }

    let status: Status

    let recipient: Recipient
    let token: Token
    let tokenFee: Token
    let userWalletState: UserWalletEnvironments

    let amountInFiat: Double
    let amountInToken: Double

    let fee: FeeAmount
    let feeInToken: FeeAmount

    public init(
        status: Status,
        recipient: Recipient,
        token: Token,
        tokenFee: Token,
        userWalletState: UserWalletEnvironments,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount,
        feeInToken: FeeAmount
    ) {
        self.status = status
        self.recipient = recipient
        self.token = token
        self.tokenFee = tokenFee
        self.userWalletState = userWalletState
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.fee = fee
        self.feeInToken = feeInToken
    }

    func copy(
        status: Status? = nil,
        recipient: Recipient? = nil,
        token: Token? = nil,
        tokenFee: Token? = nil,
        userWalletState: UserWalletEnvironments? = nil,
        amountInFiat: Double? = nil,
        amountInToken: Double? = nil,
        fee: FeeAmount? = nil,
        feeInToken: FeeAmount? = nil
    ) -> SendInputState {
        .init(
            status: status ?? self.status,
            recipient: recipient ?? self.recipient,
            token: token ?? self.token,
            tokenFee: tokenFee ?? self.tokenFee,
            userWalletState: userWalletState ?? self.userWalletState,
            amountInFiat: amountInFiat ?? self.amountInFiat,
            amountInToken: amountInToken ?? self.amountInToken,
            fee: fee ?? self.fee,
            feeInToken: feeInToken ?? self.feeInToken
        )
    }
}
