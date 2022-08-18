// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public protocol TKeyFacade {
    func initialize() async throws
    
    func signUp(tokenID: TokenID) async throws -> SignUpResult
    func signIn(tokenID: TokenID, deviceShare: String) async throws -> SignInResult
    func signIn(tokenID: TokenID, customShare: String) async throws -> SignInResult
    func signIn(deviceShare: String, customShare: String) async throws -> SignInResult
}

struct TKeyFacadeError: Error, Codable {
    let name: String
    let code: Int
    let message: String
    let original: String?
}
