//
//  SendInputBusinessLogic+ValidationChain.swift
//  Send
//
//  Created by Giang Long Tran on 26.12.2022.
//

import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    fileprivate static func checkIsReady(_ state: SendInputState) -> Bool {
        switch state.status {
        case .requiredInitialize:
            return false
        case .error(reason: .requiredInitialize):
            return false
        case .error(reason: .initializeFailed(_)):
            return false
        default:
            return true
        }
    }

    fileprivate static func validateInputAmount(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(status: .error(reason: .missingFeeRelayer))
        }
        let amountLamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        var status: SendInputState.Status = .ready

        // Limit amount with logic for SPL and SOL tokens
        let strategy: ChainStrategy.Type = state.token.isNativeSOL ? NativeTokenStrategy.self : SPLTokenStrategy.self
        var state = await strategy.validateInput(state, service)

        if !SendInputBusinessLogic.checkIsReady(state) {
            status = .error(reason: .requiredInitialize)
        }

        return state.copy(status: status)
    }

    fileprivate static func validateFee(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState {
        guard state.fee != .zero else { return state }
        guard let wallet: Wallet = state.userWalletEnvironments.wallets
            .first(where: { (wallet: Wallet) in wallet.token.address == state.tokenFee.address })
        else {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }

        if state.feeInToken.total > (wallet.lamports ?? 0) {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }
        return state
    }

    static func validationChain(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState {
        if case .error(reason: .feeCalculationFailed) = state.status { return state }

        return await executeChain(
            state,
            service,
            [
                validateInputAmount,
                validateFee
            ]
        )
    }
}
