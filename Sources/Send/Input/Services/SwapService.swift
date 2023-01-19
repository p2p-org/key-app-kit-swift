// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import FeeRelayerSwift
import OrcaSwapSwift

public protocol SwapService {
    func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount?
}

public struct MockedSwapService: SwapService {
    let result: FeeAmount?

    public init(result: FeeAmount?) { self.result = result }

    public func calculateFeeInPayingToken(
        feeInSOL _: FeeAmount,
        payingFeeTokenMint _: PublicKey
    ) async throws -> FeeAmount? { result }
}

public class SwapServiceImpl: SwapService {
    private let feeRelayerCalculator: RelayFeeCalculator
    private let orcaSwap: OrcaSwapType
    private let contextManager: RelayContextManager

    public init(
        feeRelayerCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType,
        contextManager: RelayContextManager
    ) {
        self.feeRelayerCalculator = feeRelayerCalculator
        self.orcaSwap = orcaSwap
        self.contextManager = contextManager
    }

    public func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount? {
        let context = try await contextManager.getCurrentContextOrUpdate()
        let neededTopUpAmount = try await feeRelayerCalculator.calculateNeededTopUpAmount(context, expectedFee: feeInSOL, payingTokenMint: payingFeeTokenMint)
        return try await feeRelayerCalculator.calculateFeeInPayingToken(orcaSwap: orcaSwap, feeInSOL: neededTopUpAmount, payingFeeTokenMint: payingFeeTokenMint)
    }
}
