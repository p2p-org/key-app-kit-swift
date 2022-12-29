//
//  SendInputBusinessLogic+AvailableWalletForFee.swift
//  Send
//
//  Created by Giang Long Tran on 26.12.2022.
//

import Foundation
import SolanaSwift

//extension SendInputBusinessLogic {
//    static func calculateWalletsForPayingFeeChain(_ state: SendInputState,_ services: SendInputServices) async -> SendInputState {
//        if state.fee.total == .zero {
//            return state.copy(
//                walletsForPayingFee: state.userWalletEnvironments.wallets.map { .init(wallet: $0, feeAmountInToken: .zero) }
//            )
//        }
//
//        let wallets = await withTaskGroup(of: (Wallet, FeeAmount?).self) { group -> [SendInputState.PayingWalletFee] in
//            for wallet in state.userWalletEnvironments.wallets {
//                group.addTask {
//                    (
//                        wallet,
//                        try? await services.swapService.calculateFeeInPayingToken(
//                            feeInSOL: state.fee,
//                            payingFeeTokenMint: try PublicKey(string: wallet.token.address)
//                        )
//                    )
//                }
//            }
//
//            var result: [SendInputState.PayingWalletFee] = []
//            for await calculationResult in group {
//                guard
//                    let availableAmountInWallet: Lamports = calculationResult.0.lamports,
//                    let feeAmountInToken: FeeAmount = calculationResult.1
//                else {
//                    continue
//                }
//
//                if feeAmountInToken.total <= availableAmountInWallet {
//                    result.append(.init(wallet: calculationResult.0, feeAmountInToken: feeAmountInToken))
//                }
//            }
//
//            return result
//        }
//
//        return state.copy(walletsForPayingFee: wallets)
//    }
//}
