import Foundation
import KeyAppKitCore
import Onboarding
import SolanaSwift

public protocol HistoryService {
    func transactions(secretKey: Data, pubKey: String, mint: String?, offset: Int, limit: Int) async throws -> [HistoryTransaction]
}

public class HistoryServiceImpl: HistoryService {
    let uuid = UUID()
    private let endpoint: URL
    private let networkManager: Onboarding.NetworkManager = URLSession.shared

    public init(endpoint: String) {
        self.endpoint = URL(string: endpoint)!
    }

    public func transactions(secretKey: Data, pubKey: String, mint: String?, offset: Int, limit: Int = 100) async throws -> [HistoryTransaction] {
        var params = TransactionsRequestParams(
            pubKey: pubKey,
            limit: limit,
            offset: offset,
            mint: mint
        )
        try params.signed(secretKey: secretKey)
        // Prepare
        var request = createDefaultRequest()

        let rpcRequest = JSONRPCRequest(id: uuid.uuidString, method: "get_transactions", params: params)
        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)
        let decoder = try JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try JSONDecoder().decode(KeyAppKitCore.JSONRPCResponse<[HistoryTransaction], String>.self, from: responseData)
//        if let error = response.error {
//            throw apiGatewayError(from: error)
//        }
        return response.result ?? []
    }

    private func createDefaultRequest(method: String = "POST") -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("P2PWALLET_MOBILE", forHTTPHeaderField: "CHANNEL_ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

}

extension HistoryServiceImpl {
    struct TransactionsRequestParams: Codable, Signature {
        var pubKey: String?
        var limit: Int
        var offset: Int
        var mint: String?
        var signature: String?

        enum CodingKeys: String, CodingKey {
            case pubKey = "user_id"
            case limit
            case offset
            case mint
            case signature
        }

        mutating func signed(secretKey: Data) throws {
            self.signature = try signAsBase58(secretKey: secretKey)
        }

        func serialize(to writer: inout Data) throws {
            try pubKey.serialize(to: &writer)
            try limit.serialize(to: &writer)
            try offset.serialize(to: &writer)
//            if let mint {
            try mint.serialize(to: &writer)
//            } else {
////                try 0.serialize(to: &writer)
//                try "So11111111111111111111111111111111111111112".serialize(to: &writer)
//            }
        }
    }
}
