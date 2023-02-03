import Foundation

/// Event that can be sent via AnalyticsManager
public protocol AnalyticsEvent {
    /// The name of the event
    var eventName: String? { get }
    /// Params sent with event
    var params: [String: Any]? { get }
    /// Array of excluded providers, event will not be sent to these providers when set
    var excludedProviderIds: [any AnalyticsProviderId] { get }
}
