import Amplitude
import Foundation

public final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    public init(apiKey: String) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
    }

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }
}
