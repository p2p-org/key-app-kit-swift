//
//  SendInputBusinessLogic+AutoSelectionWalletForPayingWallet.swift
//  Send
//
//  Created by Giang Long Tran on 28.12.2022.
//

import Foundation
import SolanaSwift
import FeeRelayerSwift

extension SendInputBusinessLogic {
    fileprivate static func checkPayingInSameToken(
        _ state: SendInputState,
        _ services: SendInputServices,
        _ payingWalletFee: SendInputState.PayingWalletFee
    ) -> Bool {
        guard let feeRelayerContext = state.feeRelayerContext else { return false }
        
        let inputAmountInLamport: Lamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        
        if payingWalletFee.wallet.isNativeSOL {
            // Source account must have enough SOL to pay rent exemption.
            if inputAmountInLamport + payingWalletFee.fee.total + feeRelayerContext.minimumRelayAccountBalance > (payingWalletFee.wallet.lamports ?? 0) {
                return false
            }
        } else {
            // Not enough balance to cover transfer amount + fee amount.
            if inputAmountInLamport + payingWalletFee.feeInToken.total > (payingWalletFee.wallet.lamports ?? 0) {
                return false
            }
        }
        
        return true
    }
    
    fileprivate static func checkPayingInAnotherToken(
        _ state: SendInputState,
        _ services: SendInputServices,
        _ payingWalletFee: SendInputState.PayingWalletFee
    ) -> Bool {
        if payingWalletFee.wallet.isNativeSOL {
            return isValidNative(walletFee: payingWalletFee, context: state.feeRelayerContext)
        }
        if payingWalletFee.feeInToken.total > (payingWalletFee.wallet.lamports ?? 0) {
            return false
        }
        return true
    }
    
    /// Auto selection token for paying fee, based on state.walletsForPayingFee.
    static func autoSelectionTokenFee(
        _ state: SendInputState,
        _ services: SendInputServices
    ) async -> SendInputState {
        guard state.autoSelectionTokenFee else { return state }
        
        for walletForPayingFee in state.walletsForPayingFee {
            if state.token.address == walletForPayingFee.wallet.token.address {
                // Same token case
                if checkPayingInSameToken(state, services, walletForPayingFee) {
                    return state.copy(
                        fee: walletForPayingFee.fee,
                        tokenFee: walletForPayingFee.wallet.token,
                        feeInToken: walletForPayingFee.feeInToken
                    )
                }
            } else {
                // Not same token
                if checkPayingInAnotherToken(state, services, walletForPayingFee) {
                    return state.copy(
                        fee: walletForPayingFee.fee,
                        tokenFee: walletForPayingFee.wallet.token,
                        feeInToken: walletForPayingFee.feeInToken
                    )
                }
            }
        }
 
        // Select SOL (or any token) by default if no token account can be used for paying fee.
        if state.walletsForPayingFee.isEmpty {
            return state.copy(status: .error(reason: .feeCalculationFailed))
        }
        
        let walletForPayingFee: SendInputState.PayingWalletFee =
            state.walletsForPayingFee.first(where: { $0.wallet.isNativeSOL }) ??
            state.walletsForPayingFee.first!
        
        return state.copy(
            fee: walletForPayingFee.fee,
            tokenFee: walletForPayingFee.wallet.token,
            feeInToken: walletForPayingFee.feeInToken
        )
    }

    private static func isValidNative(walletFee: SendInputState.PayingWalletFee, context: RelayContext?) -> Bool {
        guard let context = context else { return false }
        let leftAmount = (Int64(walletFee.wallet.lamports ?? 0) - Int64(walletFee.feeInToken.total))
        return leftAmount >= Int64(context.minimumRelayAccountBalance) || leftAmount == .zero
    }
}
