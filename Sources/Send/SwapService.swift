// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public protocol SwapService {
    func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount?
}

public struct MockedExchangeService: SwapService {
    let result: FeeAmount?

    init(result: FeeAmount?) { self.result = result }

    public func calculateFeeInPayingToken(
        feeInSOL _: FeeAmount,
        payingFeeTokenMint _: PublicKey
    ) async throws -> FeeAmount? { result }
}
