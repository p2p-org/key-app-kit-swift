import XCTest
@testable import Send
import SolanaSwift

class SendViaLinkDataServiceImplTests: XCTestCase {
    
    var service: SendViaLinkDataServiceImpl!
    let validSeed = "e0EKk5xKdsO4BOh~"
    let host = "test.example.com"
    let salt = "testSalt"
    let passphrase = "testPassphrase"
    
    override func setUp() {
        super.setUp()
        
        // Initialize the service with your desired parameters
        service = SendViaLinkDataServiceImpl(
            salt: salt,
            passphrase: passphrase,
            network: .mainnetBeta,
            derivablePath: .default,
            host: host,
            solanaAPIClient: MockSolanaAPIClient()
        )
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Seed validation

    func testCheckSeedValidation_ShouldReturnSuccess() {
        let seed = "Abcde1234!$()*+,"
        XCTAssertNoThrow(try service.checkSeedValidation(seed: seed))
    }
    
    func testCheckSeedValidation_ShouldReturnFailure() {
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithSmallerLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithGreaterLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithInvalidCharacter)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - Create URL

    func testCreateURL_ShouldNotCrash() throws {
        _ = service.createURL()
    }
    
    // MARK: - Restore URL

    func testRestoreURL_WithValidSeed_ShouldReturnSuccess() throws {
        let expectedURLString = "https://test.example.com/\(validSeed)"
        let url = try service.restoreURL(givenSeed: validSeed)
        
        XCTAssertEqual(url.absoluteString, expectedURLString)
    }
    
    func testRestoreURL_WithInvalidSeed_ShouldReturnFailure() throws {
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithSmallerLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithGreaterLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithInvalidCharacter)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - GetSeedFromURL
    
    func testGetSeedFromURL_WithValidURL_ShouldReturnSuccess() throws {
        let url = URL(string: "https://test.example.com/\(validSeed)")!
        let resultSeed = try service.getSeedFromURL(url)
        
        XCTAssertEqual(resultSeed, validSeed)
    }
    
    func testGetSeedFromURL_WithInvalidURL_ShouldReturnFailure() throws {
        XCTAssertThrowsError(try service.getSeedFromURL(inValidHostWithSeed(validSeed))) { error in
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidURL)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithSmallerLength))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithGreaterLength))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithInvalidCharacter))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - generate KeyPair

    func testGenerateKeyPair_WithValidURL_ShouldReturnSuccess() async throws {
        let keyPair = try await service.generateKeyPair(url: validHostWithSeed(validSeed))
        let secretKey = "IkJEeUOufBVp14mjwuHiIb6GkAqPL+w4S95Qw/i6WLFmGS9BVzhQVAQ9Kta7r9fHy0JHO4W7K7q9G88xBV6OnA=="
        let publicKey = "7sYroAgRW6TmmXTHH7vwG2yZFUVhN7u8j8iArywLUcgs"
        
        // Ensure the key pair has been generated correctly
        XCTAssertEqual(keyPair.secretKey.base64EncodedString(), secretKey)
        XCTAssertEqual(keyPair.publicKey.base58EncodedString, publicKey)
    }
    
    func testGenerateKeyPair_WithInValidURL_ShouldReturnFailure() async throws {
        do {
            _ = try await service.generateKeyPair(url: inValidHostWithSeed(validSeed))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidURL)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithSmallerLength))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithGreaterLength))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithInvalidCharacter))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    
    // MARK: - Helper
    
    func validHostWithSeed(_ seed: String) -> URL {
        URL(string: "https://test.example.com/\(seed)")!
    }
    
    func inValidHostWithSeed(_ seed: String) -> URL {
        URL(string: "https://test.example-something.com/\(seed)")!
    }
    
    var invalidSeedWithSmallerLength: String {
        "12343232"
    }
    
    var invalidSeedWithGreaterLength: String {
        "123456789123443343"
    }
    
    var invalidSeedWithInvalidCharacter: String {
        "Abcde1234!$()*+,-.#"
    }
}

// MARK: - MockSolanaAPIClient
private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    
}
