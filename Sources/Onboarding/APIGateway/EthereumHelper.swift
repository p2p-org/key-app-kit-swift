// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoSwift
import Foundation

struct EthereumHelper {
    static func generatePublicAddress(from publicKey: Data) -> Data {
        Data(bytes: SHA3(variant: .keccak256).calculate(for: publicKey.bytes).suffix(20))
    }
}
