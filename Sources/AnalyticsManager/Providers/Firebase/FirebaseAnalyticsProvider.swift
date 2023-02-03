import Foundation
import FirebaseAnalytics

public final class FirebaseAnalyticsProvider: AnalyticsProvider {
    public init() {}

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Analytics.logEvent(
            eventName,
            parameters: event.params
        )
    }
}
