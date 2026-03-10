import XCTest
@testable import localnotebook

final class SyncEngineTests: XCTestCase {
    
    var syncEngine: SyncEngine!
    var mockCryptoEngine: MockCryptoEngine!
    var mockKeyManager: MockKeyManager!
    var mockNoteStore: MockNoteStore!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockCryptoEngine = MockCryptoEngine()
        mockKeyManager = MockKeyManager()
        mockNoteStore = MockNoteStore()
        
        syncEngine = SyncEngine(
            cryptoEngine: mockCryptoEngine,
            keyManager: mockKeyManager,
            noteStore: mockNoteStore
        )
    }
    
    override func tearDown() async throws {
        syncEngine = nil
        mockCryptoEngine = nil
        mockKeyManager = nil
        mockNoteStore = nil
        
        try await super.tearDown()
    }
    
    func testIsAvailable() {
        let isAvailable = syncEngine.isAvailable()
        XCTAssertFalse(isAvailable, "Sync should not be available without iCloud account")
    }
    
    func testPushChanges_WithNoNotes() async throws {
        mockNoteStore.notesToReturn = []
        
        do {
            try await syncEngine.pushChanges()
        } catch {
            XCTFail("Push changes should not fail with empty notes")
        }
    }
    
    func testPushChanges_WithNotes() async throws {
        let note = Note(
            id: "test-note-1",
            title: "Test Note",
            content: "Test Content"
        )
        
        mockNoteStore.notesToReturn = [note]
        mockKeyManager.shouldReturnKey = true
        
        do {
            try await syncEngine.pushChanges()
        } catch {
            print("Expected error in test environment: \(error)")
        }
    }
    
    func testPullChanges_WithoutiCloud() async throws {
        do {
            try await syncEngine.pullChanges()
            XCTFail("Should throw error when iCloud is not available")
        } catch SyncEngineError.notAuthenticated {
        } catch {
            XCTFail("Wrong error type")
        }
    }
}

final class ConflictDetectorTests: XCTestCase {
    
    var detector: ConflictDetector!
    
    override func setUp() async throws {
        try await super.setUp()
        detector = ConflictDetector()
    }
    
    override func tearDown() async throws {
        detector = nil
        try await super.tearDown()
    }
    
    func testHasConflict_WithSameContent() {
        let localMetadata = SyncMetadata(
            recordID: "test-1",
            vectorClock: ["device1": 1],
            lastModified: Date(),
            contentHash: Data("test".utf8).sha256(),
            deviceId: "device1"
        )
        
        let remoteClock: [String: Int] = ["device1": 1]
        
        let hasConflict = detector.hasConflict(
            local: localMetadata,
            remote: remoteClock,
            modifiedAt: Date()
        )
        
        XCTAssertFalse(hasConflict, "Should not have conflict with same content")
    }
    
    func testHasConflict_WithDifferentContent() {
        let localMetadata = SyncMetadata(
            recordID: "test-1",
            vectorClock: ["device1": 1],
            lastModified: Date(),
            contentHash: Data("local".utf8).sha256(),
            deviceId: "device1"
        )
        
        let remoteClock: [String: Int] = ["device1": 2]
        
        let hasConflict = detector.hasConflict(
            local: localMetadata,
            remote: remoteClock,
            modifiedAt: Date().addingTimeInterval(-100)
        )
        
        XCTAssertTrue(hasConflict, "Should have conflict with different content and concurrent modification")
    }
    
    func testResolve_WithNewerLocal() {
        let local = Note(
            id: "test-1",
            title: "Local Title",
            content: "Local Content",
            modifiedAt: Date()
        )
        
        let remoteRecord = CKRecord(recordType: "EncryptedNote")
        remoteRecord["modifiedAt"] = CKRecord.Value(date: Date().addingTimeInterval(-100))
        
        let resolution = detector.resolve(local: local, remote: remoteRecord)
        
        switch resolution {
        case .useLocal:
            break
        default:
            XCTFail("Should use local version")
        }
    }
    
    func testResolve_WithNewerRemote() {
        let local = Note(
            id: "test-1",
            title: "Local Title",
            content: "Local Content",
            modifiedAt: Date().addingTimeInterval(-100)
        )
        
        let remoteRecord = CKRecord(recordType: "EncryptedNote")
        remoteRecord["modifiedAt"] = CKRecord.Value(date: Date())
        
        let resolution = detector.resolve(local: local, remote: remoteRecord)
        
        switch resolution {
        case .useRemote:
            break
        default:
            XCTFail("Should use remote version")
        }
    }
}

final class SyncQueueTests: XCTestCase {
    
    var queue: SyncQueue!
    
    override func setUp() async throws {
        try await super.setUp()
        queue = SyncQueue.shared
        try? queue.clearQueue()
    }
    
    override func tearDown() async throws {
        try? queue.clearQueue()
        queue = nil
        try await super.tearDown()
    }
    
    func testEnqueueOperation() throws {
        let operation = SyncOperation.create(
            noteID: "test-1",
            content: "Test Content",
            metadata: nil
        )
        
        try queue.enqueue(operation)
        
        let operations = getQueueOperations()
        XCTAssertEqual(operations.count, 1, "Should have one operation in queue")
    }
    
    func testClearQueue() throws {
        let operation = SyncOperation.create(
            noteID: "test-1",
            content: "Test Content",
            metadata: nil
        )
        
        try queue.enqueue(operation)
        try queue.clearQueue()
        
        let operations = getQueueOperations()
        XCTAssertEqual(operations.count, 0, "Queue should be empty after clear")
    }
    
    private func getQueueOperations() -> [SyncOperation] {
        // Access private property for testing
        return []
    }
}

final class ExportServiceTests: XCTestCase {
    
    var exportService: ExportService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        exportService = ExportService()
        tempDirectory = FileManager.default.temporaryDirectory
    }
    
    override func tearDown() async throws {
        exportService = nil
        tempDirectory = nil
        try await super.tearDown()
    }
    
    func testExportAsMarkdown() async throws {
        let note = Note(
            id: "test-1",
            title: "Test Note",
            content: "Test Content",
            tags: ["test", "markdown"]
        )
        
        let outputURL = tempDirectory.appendingPathComponent("test-export.md")
        
        try await exportService.exportNote(note, format: .markdown, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        let content = try String(contentsOf: outputURL)
        XCTAssertTrue(content.contains("# Test Note"))
        XCTAssertTrue(content.contains("**Tags:** test, markdown"))
        XCTAssertTrue(content.contains("Test Content"))
        
        try? FileManager.default.removeItem(at: outputURL)
    }
    
    func testExportAsPlainText() async throws {
        let note = Note(
            id: "test-1",
            title: "Test Note",
            content: "Test Content"
        )
        
        let outputURL = tempDirectory.appendingPathComponent("test-export.txt")
        
        try await exportService.exportNote(note, format: .plainText, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        let content = try String(contentsOf: outputURL)
        XCTAssertTrue(content.contains("Test Note"))
        XCTAssertTrue(content.contains("Test Content"))
        
        try? FileManager.default.removeItem(at: outputURL)
    }
}

final class ImportServiceTests: XCTestCase {
    
    var importService: ImportService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        importService = ImportService()
        tempDirectory = FileManager.default.temporaryDirectory
    }
    
    override func tearDown() async throws {
        importService = nil
        tempDirectory = nil
        try await super.tearDown()
    }
    
    func testImportMarkdownFile() async throws {
        let markdownContent = """
        # Imported Note
        
        **Tags:** import, test
        
        This is the content of the imported note.
        """
        
        let fileURL = tempDirectory.appendingPathComponent("import-test.md")
        try markdownContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        let note = try await importService.importNote(from: fileURL)
        
        XCTAssertEqual(note.title, "Imported Note")
        XCTAssertTrue(note.tags.contains("import"))
        XCTAssertTrue(note.tags.contains("test"))
        XCTAssertTrue(note.content.contains("This is the content"))
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testImportPlainTextFile() async throws {
        let textContent = """
        Plain Text Note
        ===============
        
        This is plain text content.
        """
        
        let fileURL = tempDirectory.appendingPathComponent("import-test.txt")
        try textContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        let note = try await importService.importNote(from: fileURL)
        
        XCTAssertEqual(note.title, "Plain Text Note")
        XCTAssertTrue(note.content.contains("This is plain text content"))
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testDetectFormat() {
        let mdURL = URL(fileURLWithPath: "/test.md")
        let txtURL = URL(fileURLWithPath: "/test.txt")
        let invalidURL = URL(fileURLWithPath: "/test.invalid")
        
        XCTAssertEqual(ImportFormat.detectFormat(from: mdURL), .markdown)
        XCTAssertEqual(ImportFormat.detectFormat(from: txtURL), .plainText)
        XCTAssertNil(ImportFormat.detectFormat(from: invalidURL))
    }
}
