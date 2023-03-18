//
//  JupiterSwapBusinessLogicHelperSendToBlockchain.swift
//  
//
//  Created by Chung Tran on 18/03/2023.
//

import XCTest
import SolanaSwift
import Jupiter
import Swap
import Combine

final class JupiterSwapBusinessLogicHelperSendToBlockchainTests: XCTestCase {
    private var mockJupiterAPI: MockJupiterAPI!
    private var mockSolanaAPIClient: MockSolanaAPIClient!
    var account: KeyPair!
    var route: Route!
    let mockedSwapTransactionId = "mockedSwapTransactionId"
    
    override func setUpWithError() throws {
        mockJupiterAPI = MockJupiterAPI()
        mockSolanaAPIClient = MockSolanaAPIClient(
            mockedResults: [
                .success(mockedSwapTransactionId)
            ]
        )
        account = try KeyPair()
        route = .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 2)])
    }
    
    override func tearDown() async throws {
        mockJupiterAPI = nil
        mockSolanaAPIClient = nil
    }
    
    func testSendToBlockchainSuccess() async throws {
        // when
        let transactionId = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
            account: account,
            swapTransaction: mockedSwapTransactionId,
            route: route,
            jupiterClient: mockJupiterAPI,
            solanaAPIClient: mockSolanaAPIClient
        )
        
        // then
        XCTAssertEqual(transactionId, mockedSwapTransactionId)
    }
    
    func testSendToBlockchainBlockhashNotFoundThenSuccess() async throws {
        // given
        mockJupiterAPI = MockJupiterAPI()
        mockSolanaAPIClient = .init(
            mockedResults: [
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .success(mockedSwapTransactionId)
            ]
        )
        
        // when
        let transactionId = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
            account: account,
            swapTransaction: nil,
            route: route,
            jupiterClient: mockJupiterAPI,
            solanaAPIClient: mockSolanaAPIClient
        )
        
        // then
        XCTAssertEqual(transactionId, mockedSwapTransactionId)
    }
}

// MARK: - Helpers

private class MockJupiterAPI: MockJupiterAPIBase {
    override func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        asLegacyTransaction: Bool?,
        computeUnitPriceMicroLamports: Int?,
        destinationWallet: String?
    ) async throws -> String? {
        // Here, you could write your own implementation of how this method should behave during testing
        // For example, you could return a pre-defined string or throw a custom error
        
        // For the sake of simplicity, we'll just return the injected mocked response string
        "AgHBJTmqzU8iQAKWKeR/8YoUPCuaoWDRPvHnKuh4ZAyyJJ6rSsUO4EvUdmJ1h2H9b+yeL+CFdbeDWUh1YS/KdgsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAIAAgcEhDK86KdYVB1Pjs1JjKmPK6g9GAZa56V/jBPUb8rFpqKQw9EFK9Fj55SNpr+Hz9vkVpgT7w0sEDu2/Tw0PHaaGEbtKyFp3KxODcjxNK4W2DHFN7Ha7phaxzQ81WGIslAjFIwjF04y2F7VDRW+eTT8iRda0hjuzREFw+SiK58iEOgrFvHh3LzHrokvQuQWYMGkB11fhD71u6xrkYGcxUAvAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAAEedUt7b9rxezQnYRTSjSupZdQQ7Nv0CskZQu1hENZXFT4EV4IzBWhu3FRZB4z7zvsBFHOfx86dh9/tcWIB4z3AgUABQLAXBUABg8KAQILCgEHAggDCQQEBAwj5RfLl3rjrSoAAQAAAAIRAOgDAAAAAAAAuOYAAAAAAAAyAAAB8SK6ARd8JB0h7LJxdf1d0S1RAXc3LYUny5mAXvIOzloDkpOUAwEAmA=="
    }
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    var mockedResults: [Result<String, Error>]
    var attempt = -1
    
    init(mockedResults: [Result<String, Error>]) {
        self.mockedResults = mockedResults
        super.init()
    }
    
    override func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID {
        // Here, you could write your own implementation of how this method should behave during testing
        // For example, you could return a pre-defined transaction ID or throw a custom error
        
        // For the sake of simplicity, we'll just return the injected dummy transaction ID
        attempt += 1
        switch mockedResults[attempt] {
        case .success(let transactionId):
            print("mocked send transaction success: \(transactionId)")
            return transactionId
        case .failure(let failure):
            print("mocked send transaction failure: \(failure)")
            throw failure
        }
    }
}

private extension APIClientError {
    static var blockhashNotFound: Self {
        .responseError(
            ResponseError(
                code: nil,
                message: "Transaction simulation failed: Blockhash not found",
                data: nil
            )
        )
    }
}
