//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class BindingPhoneNumberTests: XCTestCase {

    private static let defaultInitialData = BindingPhoneNumberData(seedPhrase: "", ethAddress: "", customShare: "", payload: "")

    func testEnterPhoneNumber() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "123456789", channel: .sms),
                provider: APIGatewayClientImplMock()
        )
        guard case .enterOTP = nextState else {
            XCTFail("Expected .enterOTP, but was \(nextState)")
            return
        }
    }

    func testEnterOTP() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .sms, phoneNumber: "123456789", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterOTP(opt: "000000"),
                provider: APIGatewayClientImplMock()
        )
        guard case .finish = nextState else {
            XCTFail("Expected .finish, but was \(nextState)")
            return
        }
    }

    func testEnterPhoneNumberReturnEnterOTP() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "1234567890", didSend: false, data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234567890", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .enterOTP = nextState else {
            XCTFail("Expected .enterOTP, but was \(nextState)")
            return
        }
    }

    func testEnterPhoneNumberReturnBlock() async throws {
        var state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "0987654320", didSend: false, data: Self.defaultInitialData)

        var phoneNumber = 0987654321

        for i in 0...3 {
            state = try await state <- (
                    event: .enterPhoneNumber(phoneNumber: String(phoneNumber + i), channel: .call),
                    provider: APIGatewayClientImplMock()
            )
            state = try await state <- (
                    event: .back,
                    provider: APIGatewayClientImplMock()
            )
        }
        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "0987654325", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }

    func testEnterPhoneNumberErrorBroken1() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32058", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32058) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32700", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32700) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32600", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32600) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32601", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32601) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

    }

    func testEnterPhoneNumberErrorBroken2() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32602", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32602) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32603", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32603) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32052", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32052) = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }


    }

    func testEnterPhoneNumberErrorBlock() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "32053", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }


    func testBindingPhoneNumberInvalidEvent() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "1234567890", didSend: false, data: Self.defaultInitialData)
        do {
            var nextState = try await state <- (
                    event: .enterOTP(opt: "000000"),
                    provider: APIGatewayClientImplMock()
            )
            print("Current state: \(nextState)")
            XCTFail()
        } catch {

        }

    }

    func testEnterOTPErrorBroken1() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data:Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterOTP(opt: "32058"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32700"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32600"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32601"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }
    }

    func testEnterOTPErrorBroken2() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterOTP(opt: "32602"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32603"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32052"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .broken, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32053"),
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }

    func testEnterOTPErrorBlock() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .enterOTP(opt: "32053"),
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }

    func testEnterOTPResendOTPReturnBlock() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(4), channel: .call, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .resendOTP,
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }

    func testEnterOTPResendOTP() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .sms, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .resendOTP,
                provider: APIGatewayClientImplMock()
        )
        guard case .enterOTP = nextState else {
            XCTFail("Expected .finish, but was \(nextState)")
            return
        }
    }

    func testBroken() async throws {
        let state: BindingPhoneNumberState = .broken(code: 12345)

        var nextState = try await state <- (
                event: .back,
                provider: APIGatewayClientImplMock()
        )
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testBlockHome() async throws {
        let state: BindingPhoneNumberState = .block(until: .now, reason: .blockEnterPhoneNumber, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .home,
                provider: APIGatewayClientImplMock()
        )
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func tesBlockBlockFinishBlockEnterOTP() async throws {
        let state: BindingPhoneNumberState = .block(until: .now, reason: .blockEnterOTP, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .blockFinish,
                provider: APIGatewayClientImplMock()
        )
        guard case .enterPhoneNumber = nextState else {
            XCTFail("Expected .enterPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testBlockBlockFinishBlockEnterPhoneNumber() async throws {
        let state: BindingPhoneNumberState = .block(until: .now, reason: .blockEnterPhoneNumber, phoneNumber: "1234567890", data: Self.defaultInitialData)

        var nextState = try await state <- (
                event: .blockFinish,
                provider: APIGatewayClientImplMock()
        )
        guard case .enterPhoneNumber = nextState else {
            XCTFail("Expected .enterPhoneNumber, but was \(nextState)")
            return
        }
    }
}

