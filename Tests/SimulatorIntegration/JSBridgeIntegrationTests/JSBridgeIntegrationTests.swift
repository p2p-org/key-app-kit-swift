//
//  JSBridgeIntegrationTests.swift
//  JSBridgeIntegrationTests
//
//  Created by Giang Long Tran on 08.07.2022.
//

import XCTest
@testable import JSBridge
import WebKit

class JSBridgeIntegrationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }

    @MainActor func testInit() async throws {
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)

        let msg = "Hello world"
        let str = try await JSBValue(string: msg, in: context)
        try await context.this.setValue(for: "test", value: str)

        let test = try await context.this.valueForKey("test").toString()
        XCTAssertEqual(test, msg)
    }
}
