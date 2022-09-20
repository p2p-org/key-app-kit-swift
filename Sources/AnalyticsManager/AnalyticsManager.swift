//
//  AnalyticsManager .swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/06/2021.
//

import Amplitude
import Foundation

public protocol AnalyticsManager {
    func log(event: AnalyticsEvent)
    func setIdentifier(_ identifier: AnalyticsIdentifier)
}

public class AnalyticsManagerImpl: AnalyticsManager {
    public init(apiKey: String) {
        // Enable sending automatic session events
        Amplitude.instance().trackingSessionEvents = true
        // Initialize SDK
        Amplitude.instance().initializeApiKey(apiKey)
        // FIXME: Set userId later
//        Amplitude.instance().setUserId("userId")
    }

    public func log(event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        // Amplitude
        if let params = event.params {
            debugPrint([eventName, params])
            Amplitude.instance().logEvent(eventName, withEventProperties: params)
        } else {
            debugPrint([eventName])
            Amplitude.instance().logEvent(eventName)
        }
    }
    
    public func setIdentifier(_ identifier: AnalyticsIdentifier) {
        guard
            let value = identifier.value as? NSObject,
            let identify = AMPIdentify().set(identifier.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
}
