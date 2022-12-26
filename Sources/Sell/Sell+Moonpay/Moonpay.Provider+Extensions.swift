//
//  File.swift
//  
//
//  Created by Chung Tran on 23/12/2022.
//

import Foundation
import Moonpay

extension Moonpay.Provider {
    func sellTransactions(externalTransactionId: String) async throws -> [MoonpaySellDataServiceProvider.MoonpayTransaction] {
        var components = URLComponents(string: serverSideAPI.endpoint + "api/v3/sell_transactions")!
        let params = ["externalTransactionId": externalTransactionId]
        components.queryItems = params.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let urlRequest = URLRequest(url: components.url!)

        let (data, _) = try await URLSession.shared.data(from: urlRequest)
        return try JSONDecoder().decode([MoonpaySellDataServiceProvider.MoonpayTransaction].self, from: data)
    }

    func sellTransaction(id: String) async throws -> MoonpaySellDataServiceProvider.MoonpayTransaction {
        var components = URLComponents(string: api.endpoint + "v3/sell_transactions/\(id)")!
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let urlRequest = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(from: urlRequest)
        return try JSONDecoder().decode(MoonpaySellDataServiceProvider.MoonpayTransaction.self, from: data)
    }

    func deleteSellTransaction(id: String) async throws {
        let components = URLComponents(string: serverSideAPI.endpoint + "api/v3/sell_transactions/\(id)")!
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "DELETE"
        let (_, _) = try await URLSession.shared.data(from: urlRequest)
    }
}

@available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
extension URLSession {
    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
