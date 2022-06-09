// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct Name: Decodable {
    public let address: String?
    public let name: String?
    public let parent: String?
}

public struct Owner: Decodable {
    public let parentName, owner, ownerClass: String
    public let name: String?

    enum CodingKeys: String, CodingKey {
        case parentName = "parent_name"
        case owner
        case ownerClass = "class"
        case name
    }
}

public struct PostParams: Encodable {
    public init(owner: String, credentials: PostParams.Credentials) {
        self.owner = owner
        self.credentials = credentials
    }

    public let owner: String
    public let credentials: Credentials

    public struct Credentials: Encodable {
        public init(geetest_validate: String, geetest_seccode: String, geetest_challenge: String) {
            self.geetest_validate = geetest_validate
            self.geetest_seccode = geetest_seccode
            self.geetest_challenge = geetest_challenge
        }

        let geetest_validate: String
        let geetest_seccode: String
        let geetest_challenge: String
    }
}

public struct PostResponse: Decodable {
    public let signature: String
}

public enum NameServiceError: Swift.Error, Equatable {
    case invalidURL
    case invalidResponseCode
    case invalidStatusCode(Int)
    case unknown

    public static var notFound: Self {
        .invalidStatusCode(404)
    }
}
