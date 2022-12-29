// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

typealias SendInputLogicChainNode = (_ state: SendInputState, _ service: SendInputServices) async -> SendInputState

func executeAction(
    _: SendInputState,
    _ services: SendInputServices,
    action: () async -> SendInputState,
    chains: () -> [SendInputLogicChainNode]
) async -> SendInputState {
    let state = await action()
    return await executeChain(state, services, chains())
}

func executeChain(_ state: SendInputState, _ service: SendInputServices, _ chains: [SendInputLogicChainNode]) async -> SendInputState {
    var state = state
    for node in chains {
        state = await node(state, service)
    }
    return state
}

enum SendInputBusinessLogic {
    static func sendInputBusinessLogic(
        state: SendInputState,
        action: SendInputAction,
        services: SendInputServices
    ) async -> SendInputState {
        let newState: SendInputState

        switch action {
        case let .initialize(params):
            newState = await executeAction(state, services) {
                await initializeAction(state: state, services: services, params: params)
            } chains: {
                [
                    calculateWalletsForPayingFeeChain,
                    autoSelectionTokenFee
                ]
            }
        case let .changeAmountInToken(amount):
            newState = await executeAction(state, services) {
                await sendInputChangeAmountInTokenAction(state: state, amount: amount, services: services)
            } chains: {
                [
                    updateAmountChain,
                    autoSelectionTokenFee
                ]
            }
        case let .changeAmountInFiat(amount):
            newState = await executeAction(state, services, action: {
                await sendInputChangeAmountInTokenAction(state: state, amount: amount, services: services)
            }, chains: {
                [
                    updateAmountChain,
                    autoSelectionTokenFee
                ]
            })
        case let .changeUserToken(token):
            newState = await executeAction(state, services) {
                await changeTokenAction(state: state, token: token, services: services)
            } chains: {
                [
                    calculateWalletsForPayingFeeChain,
                    autoSelectionTokenFee
                ]
            }
        case let .changeFeeToken(feeToken):
            newState = await changeFeeTokenAction(state: state, feeToken: feeToken, services: services)
        default:
            return state
        }

        return await validationChain(newState, services)
    }

    static func handleFeeCalculationError(
        state: SendInputState,
        services _: SendInputServices,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        let error = error as NSError

        if error.isNetworkConnectionError {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .feeCalculationFailed)
        }
        return state.copy(status: status)
    }

    static func handleMinAmountCalculationError(
        state: SendInputState,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        let error = error as NSError

        if error.isNetworkConnectionError {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .unknown(error))
        }
        return state.copy(status: status)
    }
}

private extension NSError {
    var isNetworkConnectionError: Bool {
        self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet
    }
}
