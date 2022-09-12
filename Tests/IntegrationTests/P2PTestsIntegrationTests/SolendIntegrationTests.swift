import XCTest
@testable import P2P

class SolendIntegrationTests: XCTestCase {
    func testGetSolendMarketInfo() async throws {
        let solend = SolendFFIWrapper()
        let result = try await solend.getCollateralAccounts(
            rpcURL: "https://api.mainnet-beta.solana.com",
            owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7"
        )

        XCTAssertEqual(result.count, 2)
    }

    func testGetMarketInfo() async throws {
        let solend = SolendFFIWrapper()
        let result = try await solend.getMarketInfo(tokens: ["USDT", "USDC"], pool: "main")
        print(result)
        // XCTAssertEqual(result.count, 2)
    }

    func testGetUserDeposit() async throws {
        let solend = SolendFFIWrapper()
        let result = try await solend.getUserDeposits(
            owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7",
            poolAddress: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY"
        )
        XCTAssertEqual(result.count, 2)
    }

    func testGetUserDepositBySymbol() async throws {
        let solend = SolendFFIWrapper()
        let result = try await solend.getUserDepositBySymbol(
            owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7",
            symbol: "USDC",
            poolAddress: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY"
        )
        XCTAssertEqual(result.symbol, "USDC")
    }
}
