import Foundation

public protocol AnalyticsProvider {
    func logEvent(_ event: AnalyticsEvent)
}
