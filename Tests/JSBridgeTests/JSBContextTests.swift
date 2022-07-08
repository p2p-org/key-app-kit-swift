// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import WebKit
import XCTest
@testable import JSBridge

class JSContextTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }
    
    @MainActor func testInit() async throws {
        print(app.windows)
        let wkView = WKWebView()
        let context = JSBContext(wkWebView: wkView)

        let str = try await JSBValue(string: "Hello world", in: context)
        try await context.this.setValue(for: "test", value: str)

        let test = try await context.this.valueForKey("test").toString()
        print(test as Any)
    }
}
