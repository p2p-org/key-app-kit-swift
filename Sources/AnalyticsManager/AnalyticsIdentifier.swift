//
//  AnalyticsIdentifier.swift
//  AnalyticsManager
//
//  Created by Ivan on 20.09.2022.
//

import Foundation

public protocol AnalyticsIdentifier {
    var name: String { get }
    var value: Any { get }
}
