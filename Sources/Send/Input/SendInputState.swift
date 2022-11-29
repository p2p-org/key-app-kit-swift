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
    case changeFeeToken(Wallet)
    case send
}

public struct SendInputServices {
    let swapService: SwapService
    let feeService: SendFeeCalculator
    let sendService: SendService

    public init(
        swapService: SwapService,
        feeService: SendFeeCalculator,
        sendService: SendService
    ) {
        self.swapService = swapService
        self.feeService = feeService
        self.sendService = sendService
    }
}

public struct SendInputState: Equatable {
    public enum ErrorReason: Equatable {
        case networkConnectionError(NSError)
        case inputTooHigh
        case inputTooLow(Double)
        case inputZero
        case feeCalculationFailed
    }

    public enum Status: Equatable {
        case processing
        case ready
        case error(reason: ErrorReason)
    }

    public let status: Status
    public let fee: FeeAmount

    let recipient: Recipient
    let token: Token
    let tokenFee: Token
    let userWalletEnvironments: UserWalletEnvironments

    let amountInFiat: Double
    let amountInToken: Double

    let feeInToken: FeeAmount

    public init(
        status: Status,
        recipient: Recipient,
        token: Token,
        tokenFee: Token,
        userWalletEnvironments: UserWalletEnvironments,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount,
        feeInToken: FeeAmount
    ) {
        self.status = status
        self.recipient = recipient
        self.token = token
        self.tokenFee = tokenFee
        self.userWalletEnvironments = userWalletEnvironments
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.fee = fee
        self.feeInToken = feeInToken
    }

    public static func zero(
        recipient: Recipient,
        token: Token,
        feeToken: Token,
        userWalletState: UserWalletEnvironments
    ) -> SendInputState {
        SendInputState(
            status: .ready,
            recipient: recipient,
            token: token,
            tokenFee: feeToken,
            userWalletEnvironments: userWalletState,
            amountInFiat: 0,
            amountInToken: 0,
            fee: .zero,
            feeInToken: .zero
        )
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
            userWalletEnvironments: userWalletState ?? userWalletEnvironments,
            amountInFiat: amountInFiat ?? self.amountInFiat,
            amountInToken: amountInToken ?? self.amountInToken,
            fee: fee ?? self.fee,
            feeInToken: feeInToken ?? self.feeInToken
        )
    }
}

extension SendInputState {
    public var maxAmountInputInToken: Double {
        var balance: Lamports = userWalletEnvironments.wallets.first(where: { $0.token.address == token.address })?
            .lamports ?? 0

        if token.address == tokenFee.address {
            balance = balance - feeInToken.total
        }

        return Double(balance) / pow(10, Double(token.decimals))
    }

    public var maxAmountInputInFiat: Double {
        maxAmountInputInToken * (userWalletEnvironments.exchangeRate[token.symbol]?.value ?? 0)
    }
}
