//
// Created by Giang Long Tran on 28.04.2022.
//

import Foundation
import SolanaSwift

/// The parse strategy for orca swap
class OrcaSwapParseStrategy: ParseStrategy {
  /// The list of orca program signatures that will be parsed by this strategy
  private static let orcaProgramSignatures = [
    SolanaSDK.PublicKey.orcaSwapId(version: 1).base58EncodedString,
    SolanaSDK.PublicKey.orcaSwapId(version: 2).base58EncodedString,
    "9qvG1zUp8xF1Bi4m6UdRNby1BAAuaDrUxSpv4CmRRMjL", /* main deprecated */
    "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8", /* main deprecated */
  ]

  func isHandlable(with _: SolanaSDK.TransactionInfo) -> Bool { false }

  func parse(
    _: SolanaSDK.TransactionInfo,
    config _: Configuration
  ) async throws -> ParsedTransaction { fatalError("parse(_:config:) has not been implemented") }
}
