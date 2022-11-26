// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum SmartInfo {
    case empty
    case splAccount(AccountInfo)
}

extension SmartInfo: BufferLayout {
    public init(from reader: inout SolanaSwift.BinaryReader) throws {
        if reader.isEmpty {
            self = .empty
        } else if let accountInfo = try? AccountInfo.init(from: &reader) {
            self = .splAccount(accountInfo)
        } else {
            self = .empty
        }
    }
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .splAccount(let info):
            try info.serialize(to: &writer)
        default:
            return
        }
    }
}