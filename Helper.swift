//
//  Helper.swift
//  Send
//
//  Created by Giang Long Tran on 27.12.2022.
//

import Foundation

enum Skipable<T> {
    case skip
    case take(T)
}
