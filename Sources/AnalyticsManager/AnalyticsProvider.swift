import Foundation

protocol AnalyticsProvider {
    func logEvent(_ event: AnalyticsEvent)
}
