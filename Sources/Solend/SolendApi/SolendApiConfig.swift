// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let config = try? newJSONDecoder().decode(Config.self, from: jsonData)

import Foundation

struct ConfigApiModel {
    // MARK: - Config

    struct Config: Codable {
        let programID: String
        let assets: [ConfigAsset]
        let markets: [Market]
        let oracles: Oracles
    }

    // MARK: - ConfigAsset

    struct ConfigAsset: Codable {
        let name, symbol: String
        let decimals: Int
        let mintAddress: String
        let logo: String
    }

    // MARK: - Market

    struct Market: Codable {
        let name: String
        let isPrimary: Bool
        let marketDescription, creator: String
        let owner: String
        let address, authorityAddress: String
        let reserves: [Reserve]

        enum CodingKeys: String, CodingKey {
            case name, isPrimary
            case marketDescription = "description"
            case creator, owner, address, authorityAddress, reserves
        }
    }

    // MARK: - Reserve

    struct Reserve: Codable {
        let asset, address, collateralMintAddress, collateralSupplyAddress: String
        let liquidityAddress, liquidityFeeReceiverAddress: String
        let userBorrowCap, userSupplyCap: UserCap?
    }

    enum UserCap: Codable {
        case integer(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let x = try? container.decode(Int.self) {
                self = .integer(x)
                return
            }
            if let x = try? container.decode(String.self) {
                self = .string(x)
                return
            }
            throw DecodingError.typeMismatch(
                UserCap.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for UserCap")
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .integer(x):
                try container.encode(x)
            case let .string(x):
                try container.encode(x)
            }
        }
    }

    // MARK: - Oracles

    struct Oracles: Codable {
        let pythProgramID, switchboardProgramID: String
        let assets: [OraclesAsset]
    }

    // MARK: - OraclesAsset

    struct OraclesAsset: Codable {
        let asset, priceAddress, switchboardFeedAddress: String
    }
}
