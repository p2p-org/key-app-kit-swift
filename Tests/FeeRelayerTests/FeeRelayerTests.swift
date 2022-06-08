//
//  FeeRelayerTests.swift
//  
//
//  Created by Chung Tran on 08/06/2022.
//

import XCTest
import FeeRelayer

class FeeRelayerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGreet() throws {
        let string = FeeRelayerImpl().sayHello(name: "test")
        XCTAssertEqual(string, "hello, test")
    }
    
    func testTransferSPLToken() throws {
        
    }

}
