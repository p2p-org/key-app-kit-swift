// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public struct ICloudAccount {
    public let name: String?
    internal let phrase: String
    public let derivablePath: DerivablePath
    public let publicKey: String
    
    public init(name: String?, phrase: String, derivablePath: DerivablePath, publicKey: String) {
        self.name = name
        self.phrase = phrase
        self.derivablePath = derivablePath
        self.publicKey = publicKey
    }
    
    init(name: String?, phrase: String, derivablePath: DerivablePath) async throws {
        self.name = name
        self.phrase = phrase
        self.derivablePath = derivablePath

        let account = try await Account(
            phrase: phrase.components(separatedBy: " "),
            network: .mainnetBeta,
            derivablePath: derivablePath
        )
        publicKey = account.publicKey.base58EncodedString
    }
}

protocol ICloudAccountProvider {
    func getAll() async throws -> [(name: String?, phrase: String, derivablePath: DerivablePath)]
}
