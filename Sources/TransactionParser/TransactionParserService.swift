//
// Created by Giang Long Tran on 28.04.2022.
//

import Foundation
import SolanaSwift

/// The fully service that is responsible for parsing raw transaction.
class TransactionParserService: TransactionParser {
  let parseStrategies: [ParseStrategy]

  init(parseStrategies: [ParseStrategy]) { self.parseStrategies = parseStrategies }

  static func `default`(apiClient: JSONRPCAPIClient, tokensRepository: TokensRepository) -> TransactionParserService {
    .init(parseStrategies: [
      OrcaSwapParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository),
    ])
  }

  func parse(
    transactionInfo _: TransactionInfo,
    myAccount _: String?,
    myAccountSymbol _: String?,
    p2pFeePayerPubkeys _: [String]
  ) async throws
  -> ParsedTransaction {
    fatalError("parse(transactionInfo:myAccount:myAccountSymbol:p2pFeePayerPubkeys:) has not been implemented")
  }

  func parse(
    _: TransactionInfo,
    config _: Configuration
  ) async throws -> ParsedTransaction { fatalError("parse(_:config:) has not been implemented") }
}
