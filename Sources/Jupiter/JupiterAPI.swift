// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum SwapMode: String {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public protocol JupiterAPI {
    func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Response<[Route]>

    func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        destinationWallet: String?
    ) async throws -> (setup: Transaction?, swap: Transaction?, cleanup: Transaction?)
    
    func routeMap() async throws -> RouteMap
}
