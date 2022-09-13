//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

public protocol AnalyticsEvent: MirrorableEnum {
    var eventName: String? { get }
    var params: [String: Any]? { get }
}

public extension AnalyticsEvent {
    public var eventName: String? {
        mirror.label.snakeAndFirstUppercased
    }

    public var params: [String: Any]? {
        guard !mirror.params.isEmpty else { return nil }
        let formatted = mirror.params.map { ($0.key.snakeAndFirstUppercased ?? "", $0.value) }
        return Dictionary(uniqueKeysWithValues: formatted)
    }
}

private extension String {
    var snakeAndFirstUppercased: String? {
        guard let snakeCase = snakeCased() else { return nil }
        return snakeCase.prefix(1).uppercased() + snakeCase.dropFirst()
    }
}
