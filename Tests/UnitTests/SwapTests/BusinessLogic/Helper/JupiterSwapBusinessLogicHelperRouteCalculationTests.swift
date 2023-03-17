import XCTest
@testable import Swap
import SolanaSwift
@testable import Jupiter

class JupiterSwapBusinessLogicHelperRouteCalculationTests: XCTestCase {
    func testWhenAmountIsNilOrZero() async throws {
        // Given
        let preferredRouteId = "route123"
        let amountFrom: Double? = nil // or 0
        let fromTokenMint = "fromToken123"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "toToken123"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(
            mockQuoteResult: .init(
                data: [],
                timeTaken: 0,
                contextSlot: nil
            )
        )
        
        // When
        do {
            let _ = try await JupiterSwapBusinessLogic.calculateRoute(
                preferredRouteId: preferredRouteId,
                amountFrom: amountFrom,
                fromTokenMint: fromTokenMint,
                fromTokenDecimals: fromTokenDecimals,
                toTokenMint: toTokenMint,
                slippageBps: slippageBps,
                userPublicKey: userPublicKey,
                jupiterClient: jupiterClient
            )
            // Then
            XCTFail("Expected error to be thrown")
        } catch JupiterSwapError.amountFromIsZero {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testWhenFromAndTokenMintAreEquals() async throws {
        // Given
        let preferredRouteId = "route123"
        let amountFrom: Double = 100
        let fromTokenMint = "sameToken"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "sameToken"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: [], timeTaken: 0, contextSlot: nil))
        
        // When
        do {
            let _ = try await JupiterSwapBusinessLogic.calculateRoute(
                preferredRouteId: preferredRouteId,
                amountFrom: amountFrom,
                fromTokenMint: fromTokenMint,
                fromTokenDecimals: fromTokenDecimals,
                toTokenMint: toTokenMint,
                slippageBps: slippageBps,
                userPublicKey: userPublicKey,
                jupiterClient: jupiterClient
            )
            // Then
            XCTFail("Expected error to be thrown")
        } catch JupiterSwapError.fromAndToTokenAreEqual {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIfRoutesResultEmpty() async throws {
        // Given
        let preferredRouteId = "id"
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: [], timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, [])
        XCTAssertEqual(result.selectedRoute, nil)
    }
    
    func testIfPreChooseRouteIsStillAvailable() async throws {
        // Given
        let preferredRoute = Route.route(marketInfos: [.marketInfo(index: 2), .marketInfo(index: 3)])
        let preferredRouteId = preferredRoute.id
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: .mocked, timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, .mocked)
        XCTAssertEqual(result.selectedRoute, preferredRoute)
    }
    
    func testIfPreChooseRouteIsNotAvailableAnymore() async throws {
        // Given
        let preferredRouteId = "notAvailableAnymoreRoute"
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: .mocked, timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, .mocked)
        XCTAssertEqual(result.selectedRoute, [Route].mocked.first)
    }
}

// MARK: - Helpers

private class MockJupiterAPI: MockJupiterAPIBase {
    var mockQuoteResult: Jupiter.Response<[Route]>
    
    init(mockQuoteResult: Jupiter.Response<[Route]>) {
        self.mockQuoteResult = mockQuoteResult
        super.init()
    }
    
    override func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int?,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Jupiter.Response<[Route]> {
        return mockQuoteResult
    }
}

private extension Array where Element == Route {
    static var mocked: Self {
        [
            .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 2)]),
            .route(marketInfos: [.marketInfo(index: 2), .marketInfo(index: 3)]),
            .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 3)])
        ]
    }
}

private extension Route {
    static func route(marketInfos: [MarketInfo]) -> Self {
        .init(
            inAmount: "1000",
            outAmount: "1980",
            priceImpactPct: 0.1,
            marketInfos: marketInfos,
            amount: "1000",
            slippageBps: 100,
            otherAmountThreshold: "200",
            swapMode: "ExactOut",
            fees: Fees(
                signatureFee: 200,
                openOrdersDeposits: [4000, 5000, 6000],
                ataDeposits: [8000, 9000, 10000],
                totalFeeAndDeposits: 20000,
                minimumSOLForTransaction: 200000
            ),
            keyapp: KeyAppInfo(
                fee: "20",
                refundableFee: "10",
                _hash: "hash1"
            )
        )
    }
}

private extension MarketInfo {
    static func marketInfo(index: Int) -> Self {
        .init(
            id: "marketInfo\(index)",
            label: "Market Info \(index)",
            inputMint: "inputMint\(index)",
            outputMint: "outputMint\(index)",
            notEnoughLiquidity: false,
            inAmount: "300",
            outAmount: "400",
            priceImpactPct: 0.03,
            lpFee: PlatformFee(amount: "20", mint: "lpFeeMint\(index)", pct: 0.002),
            platformFee: PlatformFee(amount: "10", mint: "platformFeeMint\(index)", pct: 0.001)
        )
    }
}
