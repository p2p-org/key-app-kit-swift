// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct SolendApiProviderResponse<Result: Codable>: Codable {
    let results: Result
}

protocol SolendApiProvider {
    var deployment: String { get }
    
    func getConfig() async throws -> ConfigApiModel.Config
    func getReserves(addresses: [String]) -> SolendApiProviderResponse<[ReserveApiModel.Reserve]>
}