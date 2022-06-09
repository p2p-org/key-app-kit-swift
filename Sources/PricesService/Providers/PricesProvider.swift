import Foundation

public protocol PricesProvider {
    func getCurrentPrices(coins: [String], toFiat fiat: String) async throws -> [String: CurrentPrice?]
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord]
//    func getValueInUSD(fiat: String) async throws -> Double?
}
