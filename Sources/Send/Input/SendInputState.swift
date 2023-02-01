// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

public enum SendInputAction: Equatable {
    case initialize

    case update

    case changeAmountInFiat(Double)
    case changeAmountInToken(Double)
    case changeUserToken(Token)
    case changeFeeToken(Token)
}

public struct SendInputServices {
    let swapService: SwapService
    let feeService: SendFeeCalculator
    let solanaAPIClient: SolanaAPIClient
    let relayContextManager: RelayContextManager

    public init(swapService: SwapService, feeService: SendFeeCalculator, solanaAPIClient: SolanaAPIClient, relayContextManager: RelayContextManager) {
        self.swapService = swapService
        self.feeService = feeService
        self.solanaAPIClient = solanaAPIClient
        self.relayContextManager = relayContextManager
    }
}

public struct SendInputState: Equatable {
    public enum ErrorReason: Equatable {
        case networkConnectionError(NSError)

        // Validation phase error
        case inputTooHigh(Double)
        case inputTooLow(Double)
        case insufficientFunds
        case insufficientAmountToCoverFee

        // Update fee phase error
        case feeCalculationFailed

        case requiredInitialize
        case initializeFailed(NSError)
        case missingFeeRelayer

        case unknown(NSError)
    }

    public enum Status: Equatable {
        case requiredInitialize
        case ready
        case error(reason: ErrorReason)
    }

    public struct RecipientAdditionalInfo: Equatable {
        /// Destination wallet
        public let walletAccount: BufferInfo<SolanaAddressInfo>?

        ///  Usable when recipient category is ``Recipient.Category.solanaAddress``
        public let splAccounts: [SolanaSwift.TokenAccount<AccountInfo>]

        public init(
            walletAccount: BufferInfo<SolanaAddressInfo>?,
            splAccounts: [SolanaSwift.TokenAccount<AccountInfo>]
        ) {
            self.walletAccount = walletAccount
            self.splAccounts = splAccounts
        }

        public static let zero: RecipientAdditionalInfo = .init(
            walletAccount: nil,
            splAccounts: []
        )
    }

    public struct PayingWalletFee: Equatable {
        public let wallet: Wallet
        public let fee: FeeAmount
        public let feeInToken: FeeAmount

        init(wallet: Wallet, fee: FeeAmount, feeInToken: FeeAmount) {
            self.wallet = wallet
            self.fee = fee
            self.feeInToken = feeInToken
        }
    }

    public let status: Status

    public let recipient: Recipient
    public let recipientAdditionalInfo: RecipientAdditionalInfo
    public let token: Token
    public let userWalletEnvironments: UserWalletEnvironments

    public let amountInFiat: Double
    public let amountInToken: Double

    /// Amount fee in SOL
    public let fee: FeeAmount

    /// Potential wallets for paying fee
    public let walletsForPayingFee: [PayingWalletFee]

    /// Allow auto select token for paying fee
    public let autoSelectionTokenFee: Bool

    /// Selected fee token
    public let tokenFee: Token

    /// Amount fee in Token (Converted from amount fee in SOL)
    public let feeInToken: FeeAmount

    /// Fee relayer context
    ///
    /// Current state for free transactions
    public let feeRelayerContext: FeeRelayerContext?

    public init(
        status: Status,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo,
        token: Token,
        userWalletEnvironments: UserWalletEnvironments,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount,
        tokenFee: Token,
        walletsForPayingFee: [PayingWalletFee],
        autoSelectionTokenFee: Bool,
        feeInToken: FeeAmount,
        feeRelayerContext: FeeRelayerContext?
    ) {
        self.status = status
        self.recipient = recipient
        self.recipientAdditionalInfo = recipientAdditionalInfo
        self.token = token
        self.userWalletEnvironments = userWalletEnvironments
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.fee = fee
        self.tokenFee = tokenFee
        self.walletsForPayingFee = walletsForPayingFee
        self.autoSelectionTokenFee = autoSelectionTokenFee
        self.feeInToken = feeInToken
        self.feeRelayerContext = feeRelayerContext
    }

    public static func zero(
        status: Status = .requiredInitialize,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo = .zero,
        token: Token,
        feeToken: Token,
        userWalletState: UserWalletEnvironments,
        feeRelayerContext: FeeRelayerContext? = nil
    ) -> SendInputState {
        .init(
            status: status,
            recipient: recipient,
            recipientAdditionalInfo: recipientAdditionalInfo,
            token: token,
            userWalletEnvironments: userWalletState,
            amountInFiat: 0,
            amountInToken: 0,
            fee: .zero,
            tokenFee: feeToken,
            walletsForPayingFee: [],
            autoSelectionTokenFee: true,
            feeInToken: .zero,
            feeRelayerContext: feeRelayerContext
        )
    }

    func copy(
        status: Status? = nil,
        recipient: Recipient? = nil,
        recipientAdditionalInfo: RecipientAdditionalInfo? = nil,
        token: Token? = nil,
        userWalletEnvironments: UserWalletEnvironments? = nil,
        amountInFiat: Double? = nil,
        amountInToken: Double? = nil,
        fee: FeeAmount? = nil,
        tokenFee: Token? = nil,
        feeInToken: FeeAmount? = nil,
        walletsForPayingFee: [PayingWalletFee]? = nil,
        autoSelectionTokenFee: Bool? = nil,
        feeRelayerContext: FeeRelayerContext? = nil
    ) -> SendInputState {
        .init(
            status: status ?? self.status,
            recipient: recipient ?? self.recipient,
            recipientAdditionalInfo: recipientAdditionalInfo ?? self.recipientAdditionalInfo,
            token: token ?? self.token,
            userWalletEnvironments: userWalletEnvironments ?? self.userWalletEnvironments,
            amountInFiat: amountInFiat ?? self.amountInFiat,
            amountInToken: amountInToken ?? self.amountInToken,
            fee: fee ?? self.fee,
            tokenFee: tokenFee ?? self.tokenFee,
            walletsForPayingFee: walletsForPayingFee ?? self.walletsForPayingFee,
            autoSelectionTokenFee: autoSelectionTokenFee ?? self.autoSelectionTokenFee,
            feeInToken: feeInToken ?? self.feeInToken,
            feeRelayerContext: feeRelayerContext ?? self.feeRelayerContext
        )
    }
}

public extension SendInputState {
    var maxAmountInputInToken: Double {
        var balance: Lamports = userWalletEnvironments.wallets.first(where: { $0.token.address == token.address })?
            .lamports ?? 0

        if token.address == tokenFee.address {
            // Auto selection token fee is enabled, user can use max amount in wallet.
            if
                autoSelectionTokenFee,
                walletsForPayingFee
                .filter({ $0.wallet.token.address != tokenFee.address })
                .contains(where: { payingWalletFee in
                    payingWalletFee.feeInToken.total < (payingWalletFee.wallet.lamports ?? 0)
                })
            {
                return Double(balance) / pow(10, Double(token.decimals))
            } else {
                // User should send less amount to cover fee in same token.
                if balance >= feeInToken.total {
                    balance = balance - feeInToken.total
                } else {
                    return 0
                }
            }
        }

        return Double(balance) / pow(10, Double(token.decimals))
    }

    var maxAmountInputInSOLWithLeftAmount: Double {
        var maxAmountInToken = maxAmountInputInToken.toLamport(decimals: token.decimals)

        guard
            let context = feeRelayerContext, token.isNativeSOL,
            maxAmountInToken >= context.minimumRelayAccountBalance
        else { return .zero }

        maxAmountInToken = maxAmountInToken - context.minimumRelayAccountBalance
        return Double(maxAmountInToken) / pow(10, Double(token.decimals))
    }

    var sourceWallet: Wallet? {
        userWalletEnvironments.wallets.first { (wallet: Wallet) -> Bool in
            wallet.token.address == token.address
        }
    }

    var feeWallet: Wallet? {
        userWalletEnvironments.wallets.first { (wallet: Wallet) -> Bool in
            wallet.token.address == tokenFee.address
        }
    }
}

extension SendInputState {
    var isNotInitialized: Bool {
        recipientAdditionalInfo == .zero || feeRelayerContext == nil
    }
}
