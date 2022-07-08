// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public protocol JSBObject {
    /// Get js value by key. [object.property]
    func valueForKey(_ key: String) async throws -> JSBValue

    /// Set js value with key. [object.property = jsValue]
    func setValue(for key: String, value: JSBValue) async throws

    /// Invoke method of value. [object.method(args)]
    func invokeMethod(_ method: String, withArguments args: [Any]) async throws -> JSBValue
}

public class JSBValue: JSBObject {
    let name: String
    weak var currentContext: JSBContext?

    public init(in context: JSBContext, name: String? = nil) {
        // Set variable name
        if let name = name {
            self.name = name
        } else {
            self.name = context.getNewValueId()
        }

        currentContext = context
    }

    public convenience init(string: String, in context: JSBContext, name: String? = nil) async throws {
        self.init(in: context, name: name)

        let safeString = string.replacingOccurrences(of: "\"", with: "\"\"")
        try await currentContext?.rawEvaluate("\(self.name) = \"\(safeString)\"")
    }

    public func valueForKey(_ property: String) async throws -> JSBValue {
        let newValue = JSBValue(in: currentContext!)
        try await currentContext?.rawEvaluate("\(newValue.name) = \(name).\(property)")
        return newValue
    }

    public func setValue(for property: String, value: JSBValue) async throws {
        try await currentContext?.rawEvaluate("\(name).\(property) = \(value.name)")
    }

    public func invokeMethod(_: String, withArguments _: [Any]) -> JSBValue { fatalError() }

    public func toString() async throws -> String? {
        try await currentContext?.rawEvaluate("String(\(name))")
    }
}

public class JSBContext {
    private var valueId: Int = 0
    private let wkWebView: WKWebView

    private static let kJsbValueName = "_jsbValue"

    public init(wkWebView: WKWebView) { self.wkWebView = wkWebView }

    func getNewValueId() -> String {
        defer { valueId += 1 }
        return "\(JSBContext.kJsbValueName)\(valueId)"
    }

    @MainActor func rawEvaluate(_ script: String) async throws {
        let _: Any? = try await withCheckedThrowingContinuation { continuation in
            wkWebView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                continuation.resume(returning: nil)
            }
        }
    }

    @MainActor func rawEvaluate<T>(_ script: String) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            wkWebView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                continuation.resume(returning: result as? T)
            }
        }
    }

    public private(set) lazy var this: JSBValue = .init(in: self, name: "this")
}
