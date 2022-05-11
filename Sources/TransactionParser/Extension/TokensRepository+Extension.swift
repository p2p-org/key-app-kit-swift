//
// Created by Giang Long Tran on 05.05.2022.
//

import Foundation
import SolanaSwift

extension TokensRepository {
  func getTokenWithMint(_ mint: String?) async throws -> Token {
    guard let mint = mint else {
      return .unsupported(mint: nil)
    }
    return try await getTokensList().first { $0.address == mint } ?? .unsupported(mint: mint)
  }
}
