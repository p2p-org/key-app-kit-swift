//
//  Token.swift
//  Jupiter
//
//  Created by Ivan on 30.01.2023.
//

import Foundation

public struct Token: Codable {
    public let address: String
    public let chainId: Int
    public let decimals: Int
    public let name: String
    public let symbol: String
    public let logoURI: String?
    public let extensions: Extensions?
    public let tags: [String]

    public struct Extensions: Codable {
        public let coingeckoId: String?
    }

    public init(address: String, chainId: Int, decimals: Int, name: String, symbol: String, logoURI: String?, extensions: Extensions?, tags: [String]) {
        self.address = address
        self.chainId = chainId
        self.decimals = decimals
        self.name = name
        self.symbol = symbol
        self.logoURI = logoURI
        self.extensions = extensions
        self.tags = tags
    }
}
