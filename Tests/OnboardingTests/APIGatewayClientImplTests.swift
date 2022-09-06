// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import XCTest
@testable import Onboarding

class APIGatewayClientImplTests: XCTestCase {
    // func testRegisterWallet() async throws {
    //     let privateKey = "52y2jQVwqQXkNW9R9MsKMcv9ZnJnDwzJqLX4d8noB4LEpuezFQLvAb2rioKsLCChte9ELNYwN29GzVjVVUmvfQ4v"
    //     let client = APIGatewayClientImpl(endpoint: "localhost", networkManager: URLSessionMock())
    //     try await client.registerWallet(
    //         solanaPrivateKey: privateKey,
    //         ethAddress: "123",
    //         phone: "+442071838750",
    //         channel: .sms,
    //         timestampDevice: Date()
    //     )
    // }
}

private func secureRandomData(count: Int) throws -> Data {
    var bytes = [UInt8](repeating: 0, count: count)

    // Fill bytes with secure random data
    let status = SecRandomCopyBytes(
        kSecRandomDefault,
        count,
        &bytes
    )
    
    // A status of errSecSuccess indicates success
    if status == errSecSuccess {
        // Convert bytes to Data
        let data = Data(bytes: bytes, count: count)
        return data
    } else {
        // Handle error
        return Data()
    }
}
