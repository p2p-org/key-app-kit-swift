// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService

class MockedNameService: NameService {
    func getName(_: String) async throws -> String? { fatalError("getName(_:) has not been implemented") }

    func getOwnerAddress(
        _: String
    ) async throws -> String? { fatalError("getOwnerAddress(_:) has not been implemented") }

    func getOwners(_: String) async throws -> [NameRecord] { fatalError("getOwners(_:) has not been implemented") }

    func create(
        name _: String,
        publicKey _: String,
        privateKey _: Data
    ) async throws -> CreateNameTransaction { fatalError("create(name:publicKey:privateKey:) has not been implemented")
    }

    func post(
        name _: String,
        params _: PostParams
    ) async throws -> PostResponse { fatalError("post(name:params:) has not been implemented") }
}
