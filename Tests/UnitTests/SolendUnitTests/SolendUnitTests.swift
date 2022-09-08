import P2pSdk
import XCTest
@testable import Solend

class SolendUnitTests: XCTestCase {
    func testGetSolendMarketInfo() async throws {
        let service = SolendServiceImpl()
        print(try await service.getCollateralAccounts(
            rpcURL: "https://api.mainnet-beta.solana.com",
            owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7"
        ))
    }
}
