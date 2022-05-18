// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

class TransactionParserImpl: TransactionParserService {
  let apiClient: SolanaAPIClient
  let strategies: [TransactionParseStrategy]
  let feeParserStrategy: FeeParseStrategy

  init(apiClient: SolanaAPIClient, strategies: [TransactionParseStrategy], feeParserStrategy: FeeParseStrategy) {
    self.apiClient = apiClient
    self.strategies = strategies
    self.feeParserStrategy = feeParserStrategy
  }

  func parse(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> ParsedTransaction {
    var status = ParsedTransaction.Status.confirmed

    if transactionInfo.meta?.err != nil {
      let errorMessage = transactionInfo.meta?.logMessages?
        .first(where: { $0.contains("Program log: Error:") })?
        .replacingOccurrences(of: "Program log: Error: ", with: "")
      status = .error(errorMessage)
    }

    let (info, fee): (AnyHashable?, FeeAmount) = try await(
      parseTransaction(transactionInfo: transactionInfo, config: configuration),
      parseFee(transactionInfo: transactionInfo, config: configuration)
    )

    return ParsedTransaction(
      status: status,
      signature: transactionInfo.transaction.signatures.first,
      info: info,
      slot: transactionInfo.slot,
      blockTime: transactionInfo.blockTime?.asDate(),
      fee: fee,
      blockhash: transactionInfo.transaction.message.recentBlockhash
    )
  }

  private func parseTransaction(
    transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable? {
    for strategy in strategies {
      if strategy.isHandlable(with: transactionInfo) {
        let info = try await strategy.parse(transactionInfo, config: configuration)

        guard let info = info else { continue }
        return info
      }
    }

    return nil
  }

  private func parseFee(
    transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> FeeAmount {
    try await feeParserStrategy.parse(transactionInfo: transactionInfo, feePayers: configuration.feePayers)
  }
}

private extension UInt64 {
  func asDate() -> Date {
    Date(timeIntervalSince1970: TimeInterval(self))
  }
}
