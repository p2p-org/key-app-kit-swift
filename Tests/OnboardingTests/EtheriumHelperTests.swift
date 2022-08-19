// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import XCTest
@testable import Onboarding

class EtheriumHelperTests: XCTestCase {
    func testValidNumber() async throws {
        let publicKey =
            Data(
                hex: "a73e7a935e27918aab35e71bbc15542d6e9f2dd51d5c2b8c2fcecb3616619f2cc533596c775ce4b93a78d0d7bb318da200db80bfcc0821ef25b73669bf03b75b"
            )
        let address = EthereumHelper.generatePublicAddress(from: publicKey)
        XCTAssertEqual(address.hexString, "2971f12de1794f46f52e4f931c45232c557d7874")
    }
}
