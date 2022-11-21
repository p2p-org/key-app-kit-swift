// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import XCTest
@testable import Send

class RecipientSearchServiceImplTest: XCTestCase {
    let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
        wallets: [],
        exchangeRate: [:]
    )

    func testOkTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(input: "kirill", env: defaultInitialWalletEnvs)
        expectResult(.ok([]), result)
    }

    func testInvalidLongInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(
            input: "epstein didn’t kill himself",
            env: defaultInitialWalletEnvs
        )
        expectResult(.invalidInput, result)
    }

    func testInvalidShort1SymbolInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(input: "e", env: defaultInitialWalletEnvs)
        expectResult(.invalidInput, result)
    }

    func testInvalidShort2SymbolsInputTests() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(input: "ea", env: defaultInitialWalletEnvs)
        expectResult(.invalidInput, result)
    }

    func testMissingToken() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(
            input: "8upjSpvjcdpuzhfR1zriwg5NXkwDruejqNE9WNbPRtyA",
            env: defaultInitialWalletEnvs
        )
        expectResult(
            .missingUserToken(recipient: .init(address: "", category: .solanaAddress, hasFunds: false)),
            result
        )
    }

    func testNameServiceError() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(
            input: "long",
            env: defaultInitialWalletEnvs
        )
        expectResult(.solanaServiceError(NSError(domain: "Internal error", code: 500)), result)
    }

    // func testNoRenBTCError() async throws {
    //     let service = RecipientSearchServiceImpl(nameService: MockedNameService())
    //
    //     let result = try await service.search(
    //         input: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
    //         state: userWalletState
    //     )
    //     expectResult(.notEnoughRenBTC, result)
    // }

    func testInsufficientUserFunds() async throws {
        let service = RecipientSearchServiceImpl(nameService: MockedNameService())

        let result = await service.search(
            input: "7kWt998XAv4GCPkvexE5Jhjhv3UqEaDgPhKVCsJXKYu8",
            env: defaultInitialWalletEnvs
        )
        expectResult(.insufficientUserFunds, result)
    }

    private func expectResult(_ result: RecipientSearchResult, _ actual: RecipientSearchResult) {
        if result != actual { XCTFail() }
    }
}
