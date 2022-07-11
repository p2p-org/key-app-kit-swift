// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol JSBridge {
    /// Get js value by key. [object.property]
    func valueForKey(_ key: String) async throws -> JSBValue

    /// Set js value with key. [object.property = jsValue]
    func setValue(for key: String, value: JSBValue) async throws

    /// Invoke method of value. [object.method(args)]
    func invokeMethod<T: CustomStringConvertible>(_ method: String, withArguments args: [T]) async throws -> JSBValue

    func invokeAsyncMethod<T: CustomStringConvertible>(
        _ method: String,
        withArguments args: [T]
    ) async throws -> JSBValue
}
