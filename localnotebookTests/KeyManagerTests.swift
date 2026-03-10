import XCTest
@testable import localnotebook

final class KeyManagerTests: XCTestCase {
    var keyManager: KeyManager!
    let testIdentifier = "testKey"
    
    override func setUp() {
        super.setUp()
        keyManager = KeyManager(keychainService: "com.privernote.test")
    }
    
    override func tearDown() {
        try? keyManager.deleteKey(identifier: testIdentifier)
        keyManager = nil
        super.tearDown()
    }
    
    func testDeriveKeyFromPassword() throws {
        let password = "testPassword123"
        let salt = Data(repeating: 0x01, count: 32)
        
        let key = try keyManager.deriveKeyFromPassword(password, salt: salt)
        
        XCTAssertNotNil(key)
    }
    
    func testStoreAndRetrieveKey() throws {
        let key = SymmetricKey(size: .bits256)
        
        try keyManager.storeKey(key, identifier: testIdentifier)
        let retrievedKey = try keyManager.retrieveKey(identifier: testIdentifier)
        
        XCTAssertEqual(key, retrievedKey)
    }
    
    func testKeyExists() throws {
        XCTAssertFalse(keyManager.keyExists(identifier: testIdentifier))
        
        let key = SymmetricKey(size: .bits256)
        try keyManager.storeKey(key, identifier: testIdentifier)
        
        XCTAssertTrue(keyManager.keyExists(identifier: testIdentifier))
    }
    
    func testDeleteKey() throws {
        let key = SymmetricKey(size: .bits256)
        try keyManager.storeKey(key, identifier: testIdentifier)
        
        try keyManager.deleteKey(identifier: testIdentifier)
        
        XCTAssertFalse(keyManager.keyExists(identifier: testIdentifier))
    }
    
    func testDeriveSameKeyFromSamePassword() throws {
        let password = "testPassword123"
        let salt = Data(repeating: 0x01, count: 32)
        
        let key1 = try keyManager.deriveKeyFromPassword(password, salt: salt)
        let key2 = try keyManager.deriveKeyFromPassword(password, salt: salt)
        
        XCTAssertEqual(key1, key2)
    }
}
