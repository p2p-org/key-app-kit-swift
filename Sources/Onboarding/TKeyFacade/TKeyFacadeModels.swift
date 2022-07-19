// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

import Foundation

public enum Provider {
    case google
    case apple
}

public struct TokenID {
    public let value: String
    public let provider: Provider
    
    public init(value: String, provider: Provider) {
        self.value = value
        self.provider = provider
    }
}

public typealias DeviceShare = String

public struct SignUpResult: Codable {
    public let privateSOL: String
    public let reconstructedETH: String
    public let deviceShare: String
}

public struct SignInResult: Codable {
    public let privateSOL: String
    public let reconstructedETH: String
}
