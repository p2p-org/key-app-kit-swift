import Foundation

public protocol AnalyticsProviderId: RawRepresentable<String> {}

public protocol AnalyticsProvider {
    var providerId: any AnalyticsProviderId { get }
    func logEvent(_ event: AnalyticsEvent)
}
