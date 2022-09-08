import P2pSdk
@testable import Solend
import XCTest

class SolendUnitTests: XCTestCase {
    func testGetSolendMarketInfo() throws {
        let service = SolendServiceImpl()
        
        let result = get_solend_collateral_accounts(
            "https://api.mainnet-beta.solana.com/",
            "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7"
        )
        let string = String(cString: result!)
        print(string)
    }
}
