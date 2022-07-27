// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension CreateWalletState {
    func socialSignInAccountWasUsedHandler(
        currentState: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case let .signIn(tokenID, authProvider, email):
            return try await socialSignInHandler(currentState: currentState, event: event, provider: provider)
        case let .signInRerouteToRestore(signInProvider, email):
            return .finishWithRerouteToRestore(signInProvider: signInProvider, email: email)
        case let .signInBack:
            return .socialSignIn
        default:
            throw StateMachineError.invalidEvent
        }
    }
}
