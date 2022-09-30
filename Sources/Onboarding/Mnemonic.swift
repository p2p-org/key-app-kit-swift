// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

internal func extractSeedPhrase(phrase: String, path: String) throws -> Data {
    let mnemonic = try Mnemonic(phrase: phrase.components(separatedBy: " "))

    print(mnemonic.seed.toHexString())
    let secretKey = try Ed25519HDKey.derivePath(path, seed: mnemonic.seed.toHexString()).get().key
    return secretKey
}

internal func extractSeedPhrase2(phrase: String, path _: String) async throws {
    let account = try await Account(phrase: phrase.components(separatedBy: " "), network: .mainnetBeta)
    print("Here")
    print(account.publicKey.base58EncodedString)
}
