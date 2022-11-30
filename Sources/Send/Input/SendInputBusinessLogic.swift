// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

struct SendInputBusinessLogic {
    static func sendInputBusinessLogic(
        state: SendInputState,
        action: SendInputAction,
        services: SendInputServices
    ) async -> SendInputState {
        switch action {
        case let .changeAmountInToken(amount):
            return await sendInputChangeAmountInToken(state: state, amount: amount, services: services)
        case let .changeAmountInFiat(amount):
            return await sendInputChangeAmountInFiat(state: state, amount: amount, services: services)
        case let .changeUserToken(walletToken):
            return try await changeToken(state: state, token: walletToken, services: services)
        case let .changeFeeToken(feeToken):
            return try await changeFeeToken(state: state, feeToken: feeToken, services: services)
        default:
            return state
        }
    }

    static func sendInputChangeAmountInFiat(
        state: SendInputState,
        amount: Double,
        services: SendInputServices
    ) async -> SendInputState {
        guard let price = state.userWalletEnvironments.exchangeRate[state.token.token.symbol]?.value else {
            return await sendInputChangeAmountInToken(state: state, amount: 0, services: services)
        }
        let amountInToken = amount / price
        return await sendInputChangeAmountInToken(state: state, amount: amountInToken, services: services)
    }

    static func sendInputChangeAmountInToken(
        state: SendInputState,
        amount: Double,
        services _: SendInputServices
    ) async -> SendInputState {
        let userTokenAccount: Wallet? = state.userWalletEnvironments.wallets
            .first(where: { $0.token.symbol == state.token.token.symbol })
        let tokenBalance = userTokenAccount?.lamports ?? 0
        let amountLamports = Lamports(amount * pow(10, Double(state.token.token.decimals)))

        var status: SendInputState.Status = .ready

        // More than available amount in wallet
        if state.token.token.address == state.tokenFee.token.address {
            if amountLamports + state.feeInToken.total > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        } else {
            if amountLamports > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        }

        if amount == .zero {
            status = .error(reason: .inputZero)
        } else if state.token.isNativeSOL {
            if amountLamports < state.userWalletEnvironments.rentExemptionAmountForWalletAccount {
                let minAmount = state.userWalletEnvironments.rentExemptionAmountForWalletAccount.convertToBalance(decimals: state.token.token.decimals)
                status = .error(reason: .inputTooLow(minAmount))
            }
        } else {
            if amountLamports < state.userWalletEnvironments.rentExemptionAmountForSPLAccount {
                let minAmount = state.userWalletEnvironments.rentExemptionAmountForSPLAccount.convertToBalance(decimals: state.token.token.decimals)
                status = .error(reason: .inputTooLow(minAmount))
            }
        }

        return state.copy(
            status: status,
            amountInFiat: amount * (state.userWalletEnvironments.exchangeRate[state.token.token.symbol]?.value ?? 0),
            amountInToken: amount
        )
    }

    static func changeToken(
        state: SendInputState,
        token: Wallet,
        services: SendInputServices
    ) async -> SendInputState {
        do {
            let fee = try await services.feeService.getFees(from: token, receiver: state.recipient.address, payingTokenMint: state.tokenFee.token.address) ?? .zero
            var feeInToken: FeeAmount = .zero
            if fee != .zero {
                feeInToken = try await services.feeService.getFeesInPayingToken(feeInSOL: fee, payingFeeToken: state.tokenFee.token) ?? .zero
            }

            return state.copy(
                token: token,
                fee: fee,
                feeInToken: feeInToken
            )
        } catch let error {
            return await handleFeeCalculationError(state: state, services: services, error: error)
        }
    }

    static func changeFeeToken(
        state: SendInputState,
        feeToken: Wallet,
        services: SendInputServices
    ) async -> SendInputState {
        do {
            let fee = try await services.feeService.getFees(from: state.token, receiver: state.recipient.address, payingTokenMint: feeToken.token.address) ?? .zero
            var feeInToken: FeeAmount = .zero
            if fee != .zero {
                feeInToken = try await services.feeService.getFeesInPayingToken(feeInSOL: fee, payingFeeToken: state.tokenFee.token) ?? .zero
            }

            return state.copy(
                tokenFee: feeToken,
                fee: fee,
                feeInToken: feeInToken
            )
        } catch let error {
            return await handleFeeCalculationError(state: state, services: services, error: error)
        }
    }

    private static func handleFeeCalculationError(
        state: SendInputState,
        services: SendInputServices,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        if let error = error as? NSError, error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .feeCalculationFailed)
        }
        return state.copy(status: status)
    }
}
