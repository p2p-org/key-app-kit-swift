// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import TransactionParser

class AccountCreationParseStrategyTests: XCTestCase {
  let endpoint = APIEndPoint.defaultEndpoints.first!

  lazy var apiClient = JSONRPCAPIClient(endpoint: endpoint)
  lazy var tokensRepository = TokensRepository(endpoint: endpoint)
  lazy var strategy = AccountCreationParseStrategy(tokensRepository: tokensRepository)

  func testParsingCreatingAccount() async throws {
    let trx = Bundle.module.decode(TransactionInfo.self, from: "trx-create-account-ok.json")

    // Parse
    let parsedTransaction = try await strategy.parse(
      trx,
      config: .init(accountView: nil, symbolView: nil, feePayers: [])
    )

    // Tests
    guard let parsedTransaction = parsedTransaction as? CreateAccountInfo else {
      XCTFail("Info should be CreateAccountInfo")
      return
    }

    XCTAssertEqual(parsedTransaction.fee, 0.00203928)
    XCTAssertEqual(parsedTransaction.newWallet?.token.symbol, "soETH")
    XCTAssertEqual(parsedTransaction.newWallet?.pubkey, "8jpWBKSoU7SXz9gJPJS53TEXXuWcg1frXLEdnfomxLwZ")
  }

  func testParsingCreatingBOPAccount() async throws {
    let trx = Bundle.module.decode(TransactionInfo.self, from: "trx-create-bop-account.json")

    // Parse
    let parsedTransaction = try await strategy.parse(
      trx,
      config: .init(accountView: nil, symbolView: nil, feePayers: [])
    )

    // Tests
    guard let parsedTransaction = parsedTransaction as? CreateAccountInfo else {
      XCTFail("Info should be SwapInfo")
      return
    }

    XCTAssertEqual(parsedTransaction.newWallet?.token.symbol, "BOP")
    XCTAssertEqual(parsedTransaction.newWallet?.pubkey, "3qjHF2CHQbPEkuq3cTbS9iwfWfSsHsqmgyMj7M2ZuVSx")
  }
}
