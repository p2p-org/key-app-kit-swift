// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import XCTest
@testable import Send

class RecipientSearchServiceImplTest: XCTestCase {
    func testOkTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(input: "kirill", state: .init(wallets: []))
        expectResult(.ok([]), result)
    }

    func testInvalidLongInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(input: "epstein didn’t kill himself", state: .init(wallets: []))
        expectResult(.invalidInput, result)
    }

    func testInvalidShort1SymbolInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(input: "e", state: .init(wallets: []))
        expectResult(.invalidInput, result)
    }

    func testInvalidShort2SymbolsInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(input: "ea", state: .init(wallets: []))
        expectResult(.invalidInput, result)
    }

    func testMissingToken() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(
            input: "8upjSpvjcdpuzhfR1zriwg5NXkwDruejqNE9WNbPRtyA",
            state: .init(wallets: [])
        )
        expectResult(.missingUserToken(recipient: .init(address: "", category: .solanaAddress, hasFunds: false)), result)
    }

    func testNameServiceError() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(
            input: "long",
            state: .init(wallets: [])
        )
        expectResult(.solanaServiceError(NSError(domain: "Internal error", code: 500)), result)
    }

    // func testNoRenBTCError() async throws {
    //     let service = RecipientSearchServiceImpl(nameService: MockedNameService())
    //
    //     let result = try await service.search(
    //         input: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
    //         state: .init(wallets: [])
    //     )
    //     expectResult(.notEnoughRenBTC, result)
    // }

    func testInsufficientUserFunds() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = try await service.search(
            input: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
            state: .init(wallets: [])
        )
        expectResult(.insufficientUserFunds, result)
    }

    private func expectResult(_ result: RecipientSearchResult, _ actual: RecipientSearchResult) {
        if result != actual { XCTFail() }
    }
}
