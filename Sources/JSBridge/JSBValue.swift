// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public class JSBValue: JSBridge, CustomStringConvertible {
    public let name: String
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

    internal init(name: String) {
        // Set variable name
        self.name = name
    }

    public convenience init(string: String, in context: JSBContext, name: String? = nil) async throws {
        self.init(in: context, name: name)
        try await currentContext?.evaluate("\(self.name) = \"\(string.safed)\"")
    }

    public convenience init(number: Int, in context: JSBContext, name: String? = nil) async throws {
        self.init(in: context, name: name)
        try await currentContext?.evaluate("\(self.name) = \(number)")
    }

    public var description: String { "JSBValue(\(name))" }

    public func valueForKey(_ property: String) async throws -> JSBValue {
        let context = try await getContext()
        return JSBValue(in: context, name: "\(name).\(property)")
    }

    public func setValue(for property: String, value: JSBValue) async throws {
        guard let context = currentContext else { throw JSBError.invalidContext }
        try await context.evaluate("\(name).\(property) = \(value.name)")
    }

    public func invokeMethod<T: CustomStringConvertible>(
        _ method: String,
        withArguments args: [T]
    ) async throws -> JSBValue {
        let context = try await getContext()
        let result = JSBValue(in: context)
        try await context.evaluate("\(result.name) = \(name).\(method)(\(try parseArgs(args)));")
        return result
    }

    public func invokeAsyncMethod<T: CustomStringConvertible>(
        _ method: String,
        withArguments args: [T]
    ) async throws -> JSBValue {
        let context = try await getContext()
        let result = JSBValue(in: context)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                let id = await context.promiseDispatchTable.register(continuation: continuation)

                let script = """
                \(name)
                     .\(method)(\(try parseArgs(args)))
                     .then((value) => {
                             \(result.name) = value;
                             window
                                .webkit
                                .messageHandlers
                                .\(JSBContext.kPromiseCallback)
                                .postMessage({id: \(id)});
                         }
                     )
                     .catch((error) => {
                             window
                                .webkit
                                .messageHandlers
                                .\(JSBContext.kPromiseCallback)
                                .postMessage({id: \(id), error: error.toString()})
                         }
                     );
                 0;
                """

                await context.wkWebView.evaluateJavaScript(script) { _, error in
                    guard let error = error else { return }
                    Task { await context.promiseDispatchTable.resolveWithError(for: id, error: error) }
                }
            }
        }
        return result
    }

    /// Parse swift args to js args.
    internal func parseArgs<T: CustomStringConvertible>(_ args: [T]) throws -> String {
        try args
            .map { arg -> String in
                if let arg = arg as? String {
                    return "\"\(arg.safed)\""
                }

                if let arg = arg as? Int {
                    return String(arg)
                }

                if arg is Double {
                    throw JSBError.floatingNumericIsNotSupport
                }

                if arg is Float {
                    throw JSBError.floatingNumericIsNotSupport
                }

                if let arg = arg as? [String: Any] {
                    return String(
                        data: try JSONSerialization.data(withJSONObject: arg, options: .sortedKeys),
                        encoding: .utf8
                    )!
                }

                if let arg = arg as? [Any] {
                    return String(
                        data: try JSONSerialization.data(withJSONObject: arg, options: .sortedKeys),
                        encoding: .utf8
                    )!
                }

                if let arg = arg as? JSBValue {
                    return arg.name
                }

                throw JSBError.invalidArgument(arg.description)
            }
            .joined(separator: ", ")
    }

    /// Get value from reference as String
    public func toString() async throws -> String? {
        try await currentContext?.evaluate("String(\(name))")
    }

    /// Get value from reference as Int
    public func toInt() async throws -> Int? {
        try await currentContext?.evaluate("\(name)")
    }

    /// Get value from reference as Dictionary
    public func toDictionary() async throws -> [String: Any]? {
        try await currentContext?.evaluate("\(name)")
    }

    /// Current context that contains this JSBValue
    private func getContext() async throws -> JSBContext {
        if let context = currentContext {
            return context
        }
        throw JSBError.invalidContext
    }
}

internal extension String {
    /// Make string be safed in js
    var safed: String {
        replacingOccurrences(of: "\"", with: "\\\"")
    }
}
