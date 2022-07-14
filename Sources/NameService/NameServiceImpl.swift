// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import LoggerService

public class NameServiceImpl: NameService {
    private let endpoint: String
    private let cache: NameServiceCacheType

    public init(endpoint: String, cache: NameServiceCacheType) {
        self.endpoint = endpoint
        self.cache = cache
    }

    public func getName(_ owner: String) async throws -> String? {
        if let result = cache.getName(for: owner) {
            return result.name
        }

        let name = try await getNames(owner).last(where: { $0.name != nil })?.name
        cache.save(name, for: owner)
        return name
    }

    public func getOwners(_ name: String) async throws -> [Owner] {
        do {
            let result: [Owner] = try await request(url: endpoint + "/resolve/\(name)")
            for record in result {
                if let name = record.name {
                    cache.save(name, for: record.owner)
                }
            }
            return result
        } catch let error as NameServiceError where error == .notFound {
            return []
        }
    }

    public func getOwnerAddress(_ name: String) async throws -> String? {
        do {
            return try await getOwner(name)?.owner
        } catch let error as NameServiceError where error == .notFound {
            return nil
        }
    }

    public func post(name: String, params: PostParams) async throws -> PostResponse {
        let urlString = "\(endpoint)/\(name)"
        let url = URL(string: urlString)!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(params)
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: urlRequest)
        try Task.checkCancellation()
        let stringResponse = String(data: data, encoding: .utf8)
        if let stringResponse = stringResponse,
           stringResponse.contains("insufficient funds for instruction")
        {
            throw NameServiceError.invalidStatusCode(500) // server error
        }
        return try JSONDecoder().decode(PostResponse.self, from: data)
    }

    private func getOwner(_ name: String) async throws -> Owner? {
        try await request(url: endpoint + "/\(name)")
    }

    private func getNames(_ owner: String) async throws -> [Name] {
        try await request(url: endpoint + "/lookup/\(owner)")
    }

    private func request<T: Decodable>(url: String) async throws -> T {
        guard let url = URL(string: url) else {
            Logger.log(event: "NameService: invalidURL", message: nil, logLevel: .error)
            throw NameServiceError.invalidURL
        }
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            Logger.log(event: "NameService: request Invalid response code", message: nil, logLevel: .error)
            throw NameServiceError.invalidResponseCode
        }
        switch response.statusCode {
        case 200 ... 299:
            try Task.checkCancellation()
            return try JSONDecoder().decode(T.self, from: data)
        default:
            Logger.log(
                event: "NameService: response code: \(response.statusCode)",
                message: String(data: data, encoding: .utf8),
                logLevel: .error
            )
            try Task.checkCancellation()
            throw NameServiceError.invalidStatusCode(response.statusCode)
        }
    }
}
