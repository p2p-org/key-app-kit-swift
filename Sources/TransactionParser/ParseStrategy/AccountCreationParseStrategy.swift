// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

class AccountCreationParseStrategy: ParseStrategy {
  private let tokensRepository: TokensRepository

  init(tokensRepository: TokensRepository) { self.tokensRepository = tokensRepository }

  func isHandlable(with transactionInfo: SolanaSwift.TransactionInfo) -> Bool {
    let instructions = transactionInfo.transaction.message.instructions
    switch instructions.count {
    case 1: return instructions[0].program == "spl-associated-token-account"
    case 2: return instructions.first?.parsed?.type == "createAccount" && instructions.last?.parsed?
      .type == "initializeAccount"
    default: return false
    }
  }

  func parse(_ transactionInfo: SolanaSwift.TransactionInfo, config _: Configuration) async throws -> AnyHashable? {
    let instructions = transactionInfo.transaction.message.instructions

    if let program = extractProgram(instructions, with: "spl-associated-token-account") {
      let token = try await tokensRepository.getTokenWithMint(program.parsed?.info.mint)
      return CreateAccountInfo(fee: nil, newWallet: Wallet(pubkey: program.parsed?.info.account, token: token))
    } else {
      let info = instructions[0].parsed?.info
      let initializeAccountInfo = instructions.last?.parsed?.info
      let fee = info?.lamports?.convertToBalance(decimals: Decimals.SOL)

      let token = try await tokensRepository.getTokenWithMint(initializeAccountInfo?.mint)
      return CreateAccountInfo(
        fee: fee,
        newWallet: Wallet(
          pubkey: info?.newAccount,
          lamports: nil,
          token: token
        )
      )
    }
  }

  func extractProgram(_ instructions: [ParsedInstruction], with name: String) -> ParsedInstruction? {
    instructions.first { $0.program == name }
  }
}
