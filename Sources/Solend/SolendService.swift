// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import P2P

protocol SolendService {}

class SolendServiceImpl: SolendService {
    private let solendSdk: Solend = SolendFFIWrapper()

    init() {}

    func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [SolendCollateralAccount] {
        try await solendSdk.getCollateralAccounts(rpcURL: rpcURL, owner: owner)
    }
}
