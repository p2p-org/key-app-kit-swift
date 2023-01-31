//
//  Token.swift
//  Jupiter
//
//  Created by Ivan on 30.01.2023.
//

import Foundation

public struct Token: Decodable {
    public let address: String
    public let chainId: Int
    public let decimals: Int
    public let name: String
    public let symbol: String
    public let logoURI: String?
    public let extensions: Extensions?
    public let tags: [String]
    
    public struct Extensions: Decodable {
        public let coingeckoId: String?
    }
}
