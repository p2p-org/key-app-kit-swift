import Foundation

public typealias AnalyticsProviderId = String

public protocol AnalyticsProvider {
    var providerId: AnalyticsProviderId { get }
    func logEvent(_ event: AnalyticsEvent)
}
