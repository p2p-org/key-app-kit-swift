// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// A generic data structure for json rpc
struct JSONRPCResponse<T: Codable>: Codable {
    let id: Int64
    let jsonrpc: String
    let result: T?
    let error: JSONRPCError?
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
}

struct JSONRPCRequest<T: Codable>: Codable {
    let id: Int64
    let jsonrpc: String = "2.0"
    let method: String
    let params: T
}
