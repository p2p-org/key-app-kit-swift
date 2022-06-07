//
//  NameService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/10/2021.
//

import Foundation

public protocol NameService {
    func getName(_ owner: String) async throws -> String?
    func getOwnerAddress(_ name: String) async throws -> String?
    func getOwners(_ name: String) async throws -> [Owner]
    func post(name: String, params: PostParams) async throws -> PostResponse
}

extension NameService {
    public func isNameAvailable(_ name: String) async throws -> Bool {
        try await getOwnerAddress(name) == nil
    }
}

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
        #if DEBUG
        print(String(describing: stringResponse))
        #endif
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
            throw NameServiceError.invalidURL
        }
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw NameServiceError.invalidResponseCode
        }
        switch response.statusCode {
        case 200 ... 299:
            try Task.checkCancellation()
            return try JSONDecoder().decode(T.self, from: data)
        default:
            try Task.checkCancellation()
            throw NameServiceError.invalidStatusCode(response.statusCode)
        }
    }
}

public struct Name: Decodable {
    public let address: String?
    public let name: String?
    public let parent: String?
}

public struct Owner: Decodable {
    public let parentName, owner, ownerClass: String
    public let name: String?
//        let data: [JSONAny]

    enum CodingKeys: String, CodingKey {
        case parentName = "parent_name"
        case owner
        case ownerClass = "class"
        case name
//            case data
    }
}

public struct PostParams: Encodable {
    public init(owner: String, credentials: PostParams.Credentials) {
        self.owner = owner
        self.credentials = credentials
    }
    
    public let owner: String
    public let credentials: Credentials

    public struct Credentials: Encodable {
        public init(geetest_validate: String, geetest_seccode: String, geetest_challenge: String) {
            self.geetest_validate = geetest_validate
            self.geetest_seccode = geetest_seccode
            self.geetest_challenge = geetest_challenge
        }
        
        let geetest_validate: String
        let geetest_seccode: String
        let geetest_challenge: String
    }
}

public struct PostResponse: Decodable {
    public let signature: String
}

public enum NameServiceError: Swift.Error, Equatable {
    case invalidURL
    case invalidResponseCode
    case invalidStatusCode(Int)
    case unknown

    public static var notFound: Self {
        .invalidStatusCode(404)
    }
}
