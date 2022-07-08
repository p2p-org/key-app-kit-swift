//
//  JSBridgeTests.swift
//  JSBridgeTests
//
//  Created by Giang Long Tran on 08.07.2022.
//

import XCTest
@testable import JSBridge
import WebKit

class JSBridgeTests: XCTestCase {

    override func setUpWithError() throws {
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)

        let str = try await JSBValue(string: "Hello world", in: context)
        try await context.this.setValue(for: "test", value: str)

        let test = try await context.this.valueForKey("test").toString()
        print(test as Any)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
