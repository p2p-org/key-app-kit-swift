// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import XCTest
@testable import Onboarding

class CryptoTests: XCTestCase {
    func testExtractSymmetricKey() async throws {
        let secretData = "Hello world"
        let randomSeed = Mnemonic().phrase.joined(separator: " ")
        let encryptedMetadata = try Crypto.encryptMetadata(
            seedPhrase: randomSeed,
            data: Data(secretData.utf8).base64EncodedData()
        )

        let decryptedMetadata = try Crypto.decryptMetadata(seedPhrase: randomSeed, encryptedMetadata: encryptedMetadata)
        
        print(randomSeed)
        print(encryptedMetadata)
        print(String(data: Data(base64Encoded: decryptedMetadata)!, encoding: .utf8)!)
    }
}
