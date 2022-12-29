// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    /// The action changes token of input state and calculate potential wallets for paying fee.
    static func changeTokenAction(state: SendInputState, token: Token, services: SendInputServices) async -> SendInputState {
        return state.copy(
            token: token,
            tokenFee: token,
            autoSelectionTokenFee: true
        )
    }
}
