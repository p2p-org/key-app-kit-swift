// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public class JupiterRestClientAPI: JupiterAPI {
    let host: String = "https://quote-api.jup.ag/v3"

    public init() {}
    
    public func getTokens() async throws -> [Token] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://cache.jup.ag/tokens")!)
        debugPrint("---data: ", String(data: data, encoding: .utf8))
        return try JSONDecoder().decode([Token].self, from: data)
    }

    public func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Response<[Route]> {
        guard var urlComponent = URLComponents(string: host + "/quote") else { throw JupiterError.invalidURL }

        // Queries
        var queries: [URLQueryItem] = [
            .init(name: "inputMint", value: inputMint),
            .init(name: "outputMint", value: outputMint),
            .init(name: "amount", value: amount),
            .init(name: "feeBps", value: String(feeBps)),
            .init(name: "userPublicKey", value: userPublicKey),
        ]

        if let swapMode = swapMode {
            queries.append(.init(name: "swapMode", value: swapMode.rawValue))
        }
        if let slippageBps = slippageBps {
            queries.append(.init(name: "slippageBps", value: String(slippageBps)))
        }
        if let onlyDirectRoutes = onlyDirectRoutes {
            queries.append(.init(name: "onlyDirectRoutes", value: String(onlyDirectRoutes)))
        }
        if let enforceSingleTx = enforceSingleTx {
            queries.append(.init(name: "enforceSingleTx", value: String(enforceSingleTx)))
        }
        urlComponent.queryItems = queries

        guard let url = urlComponent.url else { throw JupiterError.invalidURL }
        let request = URLRequest(url: url)

        let (data, _) = try await URLSession.shared.data(for: request)
        print(request.cURL())
        print(String(data: data, encoding: .utf8))
        return try JSONDecoder().decode(Response<[Route]>.self, from: data)
    }

    public func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        destinationWallet: String?
    ) async throws
    -> (setup: Transaction?, swap: Transaction?, cleanup: Transaction?) {
        struct PostData: Codable {
            let route: Route
            let userPublicKey: String
            let wrapUnwrapSol: Bool
            let feeAccount: String?
            let destinationWallet: String?
        }

        struct ResponseData: Codable {
            let setupTransaction: String?
            let swapTransaction: String?
            let cleanupTransaction: String?
        }

        guard let url = URL(string: host + "/swap") else { throw JupiterError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(PostData(
            route: route,
            userPublicKey: userPublicKey,
            wrapUnwrapSol: wrapUnwrapSol,
            feeAccount: feeAccount,
            destinationWallet: destinationWallet
        ))

        print(request.cURL())
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8))
        let result = try JSONDecoder().decode(ResponseData.self, from: data)

        let setupTrx = result.setupTransaction != nil ? try Transaction
            .from(data: Data(base64Encoded: result.setupTransaction!)!) : nil
        let swapTrx = result.swapTransaction != nil ? try Transaction
            .from(data: Data(base64Encoded: result.swapTransaction!)!) : nil
        let cleanupTrx = result.cleanupTransaction != nil ? try Transaction
            .from(data: Data(base64Encoded: result.cleanupTransaction!)!) : nil

        return (
            setup: setupTrx,
            swap: swapTrx,
            cleanup: cleanupTrx
        )
    }

    public func routeMap() async throws -> RouteMap {
        guard let url = URL(string: host + "/indexed-route-map") else { throw JupiterError.invalidURL }
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let mintKeys = json["mintKeys"] as? [String],
            let indexedRouteMap = json["indexedRouteMap"] as? [String: [Int]]
        else { throw JupiterError.invalidResponse }

        var generatedIndexesRouteMap: [String: [String]] = [:]
        for (key, value) in indexedRouteMap {
            generatedIndexesRouteMap[mintKeys[Int(key)!]] = value.map { mintKeys[$0] }
        }

        return .init(
            mintKeys: mintKeys,
            indexesRouteMap: generatedIndexesRouteMap
        )
    }
}
