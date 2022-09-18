//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class BindingPhoneNumberTests: XCTestCase {
    func testBindingPhoneNumber() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterPhoneNumber(
                        initialPhoneNumber: "1234567890",
                        didSend: false,
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine
                .accept(event: .enterPhoneNumber(phoneNumber: "1234567890",
                        channel: BindingPhoneNumberChannel.sms))
        guard case .enterOTP = nextState else {
            XCTFail("Expected .enterOTP, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumber3() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterPhoneNumber(initialPhoneNumber: "1234567890", didSend: true, data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine
                .accept(event: .enterPhoneNumber(phoneNumber: "1234567890", channel: .call))
        guard case .enterOTP = nextState else {
            XCTFail("Expected .enterOTP, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumber4() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterPhoneNumber(initialPhoneNumber: "1234567890", didSend: false, data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")),
                provider: APIGatewayClientImplMock()
        )
        var phoneNumber = 0987654321
        for i in 0...3 {
            try await stateMachine
                    .accept(event: .enterPhoneNumber(phoneNumber: String(phoneNumber + i), channel: .call))
            try await stateMachine
                    .accept(event: .back)
        }
        var nextState = try await stateMachine
                .accept(event: .enterPhoneNumber(phoneNumber: "0987654325", channel: .call))
        guard case .block = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberEnterPhoneNumberError1() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532058", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32058) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532700", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32700) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532600", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32600) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532601", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32601) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

    }

    func testBindingPhoneNumberEnterPhoneNumberError2() async throws {
        let state: BindingPhoneNumberState = .enterPhoneNumber(initialPhoneNumber: "", didSend: false, data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))

        var nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532602", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32602) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532603", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32603) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532052", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken(code: -32052) = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterPhoneNumber(phoneNumber: "1234532053", channel: .call),
                provider: APIGatewayClientImplMock()
        )
        guard case .block = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }


    func testBindingPhoneNumberInvalidEvent() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterPhoneNumber(
                        initialPhoneNumber: "1234567890",
                        didSend: true,
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )
        do {
            var nextState = try await stateMachine.accept(event: .enterOTP(opt: "000000"))
            print("Current state: \(stateMachine.currentState)")
            XCTFail()
        } catch {

        }

    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterOTP(
                        resendAttempt: .init(0),
                        channel: .sms,
                        phoneNumber: "1234567890",
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .enterOTP(opt: "000000"))
        guard case .finish = nextState else {
            XCTFail("Expected .finish, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberEnterOTPError1() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))

        var nextState = try await state <- (
                event: .enterOTP(opt: "32058"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32700"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32600"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32601"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberEnterOTPError2() async throws {
        let state: BindingPhoneNumberState = .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))

        var nextState = try await state <- (
                event: .enterOTP(opt: "32602"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32603"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
            return
        }

        nextState = try await state <- (
                event: .enterOTP(opt: "32052"),
                provider: APIGatewayClientImplMock()
        )
        guard case .broken = nextState else {
            XCTFail("Expected .block, but was \(nextState)")
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

    func testBindingPhoneNumberResendOTP1() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterOTP(
                        resendAttempt: .init(4),
                        channel: .sms,
                        phoneNumber: "1234567890",
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .resendOTP)
        guard case .block = nextState else {
            XCTFail("Expected .finish, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberResendOTP2() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterOTP(
                        resendAttempt: .init(0),
                        channel: .sms,
                        phoneNumber: "1234567890",
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .resendOTP)
        guard case .enterOTP = nextState else {
            XCTFail("Expected .finish, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberBroken() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .broken(code: 12345),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .back)
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberBlock() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .block(until: .now, reason: .blockEnterOTP, phoneNumber: "1234567890", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))
                ,
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .home)
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberBlockFinish1() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .block(until: .now, reason: .blockEnterOTP, phoneNumber: "", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))
                ,
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .blockFinish)
        guard case .enterPhoneNumber = nextState else {
            XCTFail("Expected .enterPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumberBlockFinish() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .block(until: .now, reason: .blockEnterPhoneNumber, phoneNumber: "1234567890", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))
                ,
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .blockFinish)
        guard case .enterPhoneNumber = nextState else {
            XCTFail("Expected .enterPhoneNumber, but was \(nextState)")
            return
        }
    }
}

