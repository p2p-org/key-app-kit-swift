//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

public protocol AnalyticsEvent {
    var eventName: String? { get }
    var params: [String: Any]? { get }
}
