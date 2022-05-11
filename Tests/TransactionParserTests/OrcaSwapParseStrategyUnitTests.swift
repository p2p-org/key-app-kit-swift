// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class OrcaSwapStrategyTests: XCTestCase {
  let endpoint = APIEndPoint.defaultEndpoints.first!

  lazy var apiClient = JSONRPCAPIClient(endpoint: endpoint)
  lazy var tokensRepository = TokensRepository(endpoint: endpoint)
  lazy var strategy = OrcaSwapParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository)
  
  func testParsingSuccessfulTransaction() async throws {
    let trx = Bundle.main.decode(TransactionInfo.self, from: "trx-swap-orca-ok.json")

    let parsedTransaction = try await strategy.parse(
      trx,
      config: .init(account: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT", symbol: nil, feePayers: [])
    )
    
    print(parsedTransaction)
  }
}