// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension CreateWalletState {
    func socialSignInHandler(currentState _: Self, event: Event, provider: Provider) async throws -> Self {
        switch event {
        case let .signIn(tokenID, authProvider, email):
            do {
                let result = try await provider.signUp(tokenID: .init(value: tokenID, provider: authProvider.rawValue))
                return .enterPhoneNumber(
                    solPrivateKey: result.privateSOL,
                    ethPublicKey: result.reconstructedETH,
                    deviceShare: result.deviceShare
                )
            } catch let error as TKeyFacadeError {
                switch error.code {
                case 1009:
                    return .socialSignInAccountWasUsed(signInProvider: authProvider, usedEmail: email)
                case 1666:
                    return .socialSignInTryAgain(signInProvider: authProvider, usedEmail: email)
                default:
                    throw error
                }
            }
        case .signInBack:
            return .finishWithoutResult
        default:
            throw StateMachineError.invalidEvent
        }
    }
}
