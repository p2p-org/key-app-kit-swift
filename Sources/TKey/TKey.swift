// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public protocol TKey {
    func signUp(tokenID: TokenID) async throws -> SignUpResult
    func signIn(tokenID: TokenID, deviceShare: String) async throws -> SignInResult
    func signIn(tokenID: TokenID, withCustomShare: String) async throws -> SignInResult
}