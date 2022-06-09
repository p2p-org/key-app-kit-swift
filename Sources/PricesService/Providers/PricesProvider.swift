import Foundation

/// Generic protocol to define a cryptocurrency prices provider
public protocol PricesProvider {
    /// Network manager for prices
    var pricesNetworkManager: PricesNetworkManager {get}
    
    /// Get prices of current set of coins' ticket
    /// - Parameters:
    ///   - coins: The coin tickets to fetch
    ///   - fiat: the fiat, for example: USD
    /// - Returns: The current prices
    func getCurrentPrices(coins: [String], toFiat fiat: String) async throws -> [String: CurrentPrice?]
    
    /// Get the historical prices of a given coin
    /// - Parameters:
    ///   - coinName: The coin ticket
    ///   - fiat: the fiat, for example: USD
    ///   - period: period to fetch
    /// - Returns: The records of prices in given period
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord]
    
//    func getValueInUSD(fiat: String) async throws -> Double?
}

extension PricesProvider {
    /// Generic get function for retrieving data over network
    func get<T: Decodable>(urlString: String) async throws -> T {
        let data = try await pricesNetworkManager.get(urlString: urlString)
        try Task.checkCancellation()
        return try JSONDecoder().decode(T.self, from: data)
    }
}
