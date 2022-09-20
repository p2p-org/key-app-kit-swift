//
//  AnalyticsIdentifier.swift
//  AnalyticsManager
//
//  Created by Ivan on 20.09.2022.
//

import Foundation

public protocol AnalyticsIdentifier: MirrorableEnum {
    var name: String { get }
    var value: Any { get }
}

public extension AnalyticsIdentifier {
    var name: String {
        mirror.label.snakeAndFirstUppercased ?? ""
    }

    var value: Any {
        mirror.params.values.first
    }
}

private extension String {
    var snakeAndFirstUppercased: String? {
        guard let snakeCase = snakeCased() else { return nil }
        return snakeCase.prefix(1).uppercased() + snakeCase.dropFirst()
    }
}
