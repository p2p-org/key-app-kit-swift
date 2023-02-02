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
        var currentState = state
        if currentState.isNotInitialized && action != .initialize {
            currentState = await initialize(currentState, services)
        }
        let newState: SendInputState

        switch action {
        case let .initialize:
            newState = await initialize(currentState, services)
        case let .changeAmountInToken(amount):
            newState = await executeAction(currentState, services) {
                await sendInputChangeAmountInTokenAction(state: currentState, amount: amount, services: services)
            } chains: {
                [
                    updateAmountChain,
                    autoSelectionTokenFee
                ]
            }
        case let .changeAmountInFiat(amount):
            newState = await executeAction(currentState, services, action: {
                await sendInputChangeAmountInFiat(state: currentState, amount: amount, services: services)
            }, chains: {
                [
                    updateAmountChain,
                    autoSelectionTokenFee
                ]
            })
        case let .changeUserToken(token):
            newState = await executeAction(currentState, services) {
                await changeTokenAction(state: currentState, token: token, services: services)
            } chains: {
                [
                    calculateWalletsForPayingFeeChain,
                    autoSelectionTokenFee
                ]
            }
        case let .changeFeeToken(feeToken):
            newState = await changeFeeTokenAction(state: currentState, feeToken: feeToken, services: services)
        default:
            return currentState
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

    private static func initialize(
        _ state: SendInputState,
        _ services: SendInputServices
    ) async -> SendInputState {
        return await executeAction(state, services, action: {
            await initializeAction(state: state, services: services)
        }, chains: {
            [
                calculateWalletsForPayingFeeChain,
                autoSelectionTokenFee
            ]
        })
    }
}

private extension NSError {
    var isNetworkConnectionError: Bool {
        self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet
    }
}
