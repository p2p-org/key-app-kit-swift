//
// Created by Giang Long Tran on 28.04.2022.
//

import Foundation
import OrcaSwapSwift
import SolanaSwift

/// The fully service that is responsible for parsing raw transaction.
class TransactionParserService: TransactionParser {
  func parse(
    transactionInfo _: SolanaSDK.TransactionInfo,
    myAccount _: String?,
    myAccountSymbol _: String?,
    p2pFeePayerPubkeys _: [String]
  ) async throws -> SolanaSDK
  .ParsedTransaction {
    fatalError("parse(transactionInfo:myAccount:myAccountSymbol:p2pFeePayerPubkeys:) has not been implemented")
  }

  func parse(
    _: SolanaSDK.TransactionInfo,
    config _: Configuration
  ) async throws -> ParsedTransaction { fatalError("parse(_:config:) has not been implemented") }
}
