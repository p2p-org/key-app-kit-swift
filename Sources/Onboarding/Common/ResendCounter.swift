// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

/// Resend timer interval
let EnterSMSCodeCountdownLegs: [TimeInterval] = [30, 40, 60, 90, 120]

public struct ResendCounter: Codable, Equatable {
    public internal(set) var attempt: Int
    public internal(set) var until: Date

    func intervalForCurrentAttempt() -> TimeInterval {
        let timeInterval = attempt >= EnterSMSCodeCountdownLegs.count
        ? EnterSMSCodeCountdownLegs[EnterSMSCodeCountdownLegs.count - 1]
        : EnterSMSCodeCountdownLegs[attempt]
        return timeInterval
    }

    static func zero() -> Self {
        .init(attempt: 0, until: Date().addingTimeInterval(EnterSMSCodeCountdownLegs[0]))
    }
}
