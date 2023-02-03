import AppsFlyerLib
import Foundation

public final class AppsFlyerAnalyticsProvider: NSObject, AnalyticsProvider {
    public init(appsFlyerDevKey: String, appleAppID: String) {
        #if DEBUG
            AppsFlyerLib.shared().isDebug = true
        #endif

        super.init()

        AppsFlyerLib.shared().deepLinkDelegate = self
    }

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        AppsFlyerLib.shared().logEvent(
            name: eventName,
            values: event.params,
            completionHandler: { (response: [String : Any]?, error: Error?) in
                if let response = response {
                    #if !RELEASE
                    print("In app event callback Success: ", response)
                    #endif
                }
                if let error = error {
                    #if !RELEASE
                    print("In app event callback ERROR:", error)
                    #endif
                }
            }
        )
    }
}

// MARK: - DeepLinkDelegate

extension AppsFlyerAnalyticsProvider: DeepLinkDelegate {
    public func didResolveDeepLink(_: DeepLinkResult) {}
}
