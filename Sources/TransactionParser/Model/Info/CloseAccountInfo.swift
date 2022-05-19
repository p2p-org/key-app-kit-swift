// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A struct that contains all information about closing account.
public struct CloseAccountTransactionInfo: Hashable {
  // The SOL amount of the account that will be returned.
  public let reimbursedAmount: Double?

  // The closed wallet
  public let closedWallet: Wallet?

  public init(reimbursedAmount: Double?, closedWallet: Wallet?) {
    self.reimbursedAmount = reimbursedAmount
    self.closedWallet = closedWallet
  }
}

extension CloseAccountTransactionInfo: Info {
  public var amount: Double? { reimbursedAmount ?? 0 }
  public var symbol: String? { "SOL " }
}
