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
}

public class AnalyticsManagerImpl: AnalyticsManager {
    private let providers: [AnalyticsProvider]
    
    init(providers: [AnalyticsProvider]) {
        self.providers = providers
    }

    public func log(event: AnalyticsEvent) {
        providers.forEach {
            $0.logEvent(event)
        }
    }
}
