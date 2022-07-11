// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class JSBContext: NSObject {
    internal var variableId: Int = 0
    internal var promiseDispatchTable: PromiseDispatchTable = .init()

    internal let wkWebView: WKWebView

    private static let kJsbValueName = "__localBridgeVariable"
    internal static let kPromiseCallback = "promiseCallback"

    public init(wkWebView: WKWebView? = nil) {
        self.wkWebView = wkWebView ?? WKWebView()

        super.init()

        let contentController = self.wkWebView.configuration.userContentController
        contentController.add(self, name: JSBContext.kPromiseCallback)
    }

    func getNewValueId() -> String {
        defer { variableId += 1 }
        return "\(JSBContext.kJsbValueName)\(variableId)"
    }

    @MainActor func evaluate(_ script: String) async throws {
        let _: Any? = try await withCheckedThrowingContinuation { continuation in
            wkWebView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    @MainActor func evaluate<T>(_ script: String) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            wkWebView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result as? T)
            }
        }
    }

    public private(set) lazy var this: JSBValue = .init(in: self, name: "this")
}

extension JSBContext: WKScriptMessageHandler {
    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let message = message.body as? [String: AnyObject] else { return }
        guard let id = message["id"] as? Int else { return }

        if let error = message["error"] {
            Task { await promiseDispatchTable.resolveWithError(for: Int64(id), error: JSBError.jsError(error)) }
        }

        Task { await promiseDispatchTable.resolve(for: Int64(id)) }
    }
}
