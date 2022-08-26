// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

let blockTime: TimeInterval = 10

public enum PhoneFlowBlockReason: Codable {
    case blockEnterPhoneNumber
    case blockEnterOTP
}
