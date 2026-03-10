import XCTest
@testable import localnotebook

final class CryptoEngineTests: XCTestCase {
    var cryptoEngine: CryptoEngine!
    
    override func setUp() {
        super.setUp()
        cryptoEngine = CryptoEngine()
    }
    
    override func tearDown() {
        cryptoEngine = nil
        super.tearDown()
    }
    
    func testEncryptAndDecrypt() throws {
        let key = cryptoEngine.generateRandomKey()
        let plaintext = "Hello, World!"
        
        let ciphertext = try cryptoEngine.encrypt(plaintext, with: key)
        let decrypted = try cryptoEngine.decrypt(ciphertext, with: key)
        
        XCTAssertEqual(plaintext, decrypted)
    }
    
    func testEncryptDifferentOutputs() throws {
        let key = cryptoEngine.generateRandomKey()
        let plaintext = "Test"
        
        let ciphertext1 = try cryptoEngine.encrypt(plaintext, with: key)
        let ciphertext2 = try cryptoEngine.encrypt(plaintext, with: key)
        
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }
    
    func testDecryptWithWrongKey() throws {
        let key1 = cryptoEngine.generateRandomKey()
        let key2 = cryptoEngine.generateRandomKey()
        let plaintext = "Test"
        
        let ciphertext = try cryptoEngine.encrypt(plaintext, with: key1)
        
        XCTAssertThrowsError(try cryptoEngine.decrypt(ciphertext, with: key2))
    }
    
    func testGenerateRandomBytes() throws {
        let bytes1 = try cryptoEngine.generateRandomBytes(count: 32)
        let bytes2 = try cryptoEngine.generateRandomBytes(count: 32)
        
        XCTAssertEqual(bytes1.count, 32)
        XCTAssertEqual(bytes2.count, 32)
        XCTAssertNotEqual(bytes1, bytes2)
    }
}
