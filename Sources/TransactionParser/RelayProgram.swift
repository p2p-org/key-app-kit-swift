// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum RelayProgram {
  public func id(network: Network) -> PublicKey {
    switch network {
    case .mainnetBeta:
      return "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9"
    default:
      // Devnet
      return "6xKJFyuM6UHCT8F5SBxnjGt6ZrZYjsVfnAnAeHPU775k"
    }
  }
}
