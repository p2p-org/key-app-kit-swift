// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

struct SendInputBusinessLogic {
    static func sendInputBusinessLogic(
        state: SendInputState,
        action: SendInputAction,
        services: SendInputServices
    ) async -> SendInputState {
        switch action {
        case let .initialize(feeRelayerContext):
            return await initialize(state: state, services: services, feeRelayerContext: feeRelayerContext)
        case let .changeAmountInToken(amount):
            return await sendInputChangeAmountInToken(state: state, amount: amount, services: services)
        case let .changeAmountInFiat(amount):
            return await sendInputChangeAmountInFiat(state: state, amount: amount, services: services)
        case let .changeUserToken(token):
            return await changeToken(state: state, token: token, services: services)
        case let .changeFeeToken(feeToken):
            return await changeFeeToken(state: state, feeToken: feeToken, services: services)

        default:
            return state
        }
    }

    static func initialize(
        state: SendInputState,
        services: SendInputServices,
        feeRelayerContext: FeeRelayerContext
    ) async -> SendInputState {
        var recipientAdditionalInfo = SendInputState.RecipientAdditionalInfo.zero

        if state.recipient.category == .solanaAddress {
            // Analyse destination spl addresses
            do {
                let destinationsSPLAccounts = try await services.solanaAPIClient
                    .getTokenAccountsByOwner(
                        pubkey: state.recipient.address,
                        params: .init(
                            mint: nil,
                            programId: TokenProgram.id.base58EncodedString
                        ),
                        configs: .init(encoding: "base64")
                    )
                recipientAdditionalInfo = .init(splAccounts: destinationsSPLAccounts)
            } catch {
                return state.copy(status: .error(reason: .initializeFailed(error as NSError)))
            }
        }

        let state = state.copy(
            status: .ready,
            recipientAdditionalInfo: recipientAdditionalInfo,
            feeRelayerContext: feeRelayerContext
        )
        return await changeFeeToken(state: state, feeToken: state.tokenFee, services: services)
    }

    static func sendInputChangeAmountInFiat(
        state: SendInputState,
        amount: Double,
        services: SendInputServices
    ) async -> SendInputState {
        guard let price = state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value else {
            return await sendInputChangeAmountInToken(state: state, amount: 0, services: services)
        }
        let amountInToken = amount / price
        return await sendInputChangeAmountInToken(state: state, amount: amountInToken, services: services)
    }

    static func checkIsReady(_ state: SendInputState) -> Bool { state.status == .ready }

    static func sendInputChangeAmountInToken(
        state: SendInputState,
        amount: Double,
        services _: SendInputServices
    ) async -> SendInputState {
        let userTokenAccount: Wallet? = state.userWalletEnvironments.wallets
            .first(where: { $0.token.symbol == state.token.symbol })
        let tokenBalance = userTokenAccount?.lamports ?? 0
        let amountLamports = Lamports(amount * pow(10, Double(state.token.decimals)))

        var status: SendInputState.Status = .ready

        // More than available amount in wallet
        if state.token.address == state.tokenFee.address {
            if amountLamports + state.feeInToken.total > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        } else {
            if amountLamports > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        }

        if !checkIsReady(state) {
            status = .error(reason: .requiredInitialize)
        }
        
        if amount == .zero {
            status = .error(reason: .inputZero)
        }

        return state.copy(
            status: status,
            amountInFiat: amount * (state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value ?? 0),
            amountInToken: amount
        )
    }

    static func changeToken(
        state: SendInputState,
        token: Token,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                token: token
            )
        }

        do {
            let fee = try await services.feeService.getFees(
                from: token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                payingTokenMint: state.tokenFee.address,
                feeRelayerContext: feeRelayerContext
            ) ?? .zero

            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: try PublicKey(string: state.tokenFee.address)
            ) ?? .zero

            return state.copy(
                token: token.token,
                fee: fee,
                feeInToken: feeInToken
            )
        } catch {
            return state.copy(status: .error(reason: .unknown(error as NSError)))
        }
    }

    static func changeFeeToken(
        state: SendInputState,
        feeToken: Token,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                tokenFee: feeToken
            )
        }

        do {
            let fee = try await services.feeService.getFees(
                from: state.token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                payingTokenMint: feeToken.address,
                feeRelayerContext: feeRelayerContext
            ) ?? .zero

            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: try PublicKey(string: state.tokenFee.address)
            ) ?? .zero

            return state.copy(
                fee: fee,
                tokenFee: feeToken,
                feeInToken: feeInToken
            )
        } catch {
            return await handleFeeCalculationError(state: state, services: services, error: error)
        }
    }

    private static func handleFeeCalculationError(
        state: SendInputState,
        services _: SendInputServices,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        let error = error as NSError

        if error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .feeCalculationFailed)
        }
        return state.copy(status: status)
    }
}
