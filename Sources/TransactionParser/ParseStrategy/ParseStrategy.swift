//
// Created by Giang Long Tran on 28.04.2022.
//

import Foundation
import SolanaSwift

/// A parse strategy
protocol ParseStrategy: AnyObject {
  /// Check is current parsing strategy can handle this transaction
  func isHandlable(with transactionInfo: SolanaSDK.TransactionInfo) -> Bool

  /// Parse a transaction
  func parse(
    _ transactionInfo: SolanaSDK.TransactionInfo,
    config configuration: Configuration
  ) async throws -> ParsedTransaction
}
