//===----------------------------------------------------------------------===//
//
// This source file is part of the EssentialNetwork open source project
//
// Copyright (c) 2025 Artem Kufaev
// Licensed under MIT License
//
// See https://github.com/a-kufaev/EssentialNetwork/blob/main/LICENSE for license information
//
//===----------------------------------------------------------------------===//

@testable import EssentialNetwork
import Foundation
import Testing

/// Unit tests for `MultipartDataContainer`.
///
/// Verifies adding various data types, calculating the content length, error handling,
/// and correct behavior with files and streams.
struct MultipartDataContainerTests {
    
    @Test("Creates an empty container")
    func testEmptyContainer() {
        // Given
        let container = MultipartDataContainer()
        
        // When/Then
        #expect(container.isEmpty == true)
        #expect(container.count == 0)
        #expect(container.contentLength == 0)
        #expect(container.items.isEmpty)
    }
    
    @Test("Adds a text field")
    func testAddText() {
        // Given
        let container = MultipartDataContainer()
        
        // When
        let result = container.addText(name: "username", value: "john_doe")
        
        // Then
        #expect(result === container) // Verify the fluent API
        #expect(container.count == 1)
        #expect(container.isEmpty == false)
        
        let item = container.items[0]
        #expect(item.name == "username")
        #expect(item.filename == nil)
        #expect(item.contentType == .plainText)
        #expect(item.contentLength == 8) // "john_doe".utf8.count
    }
    
    @Test("Adds arbitrary data")
    func testAddData() {
        // Given
        let container = MultipartDataContainer()
        let testData = "test data".data(using: .utf8)!
        
        // When
        let result = container.addData(name: "data", data: testData, contentType: .json)
        
        // Then
        #expect(result === container)
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "data")
        #expect(item.filename == nil)
        #expect(item.contentType == .json)
        #expect(item.contentLength == UInt64(testData.count))
    }
    
    @Test("Adds data without a contentType")
    func testAddDataWithoutContentType() {
        // Given
        let container = MultipartDataContainer()
        let testData = Data([1, 2, 3, 4])
        
        // When
        container.addData(name: "binary", data: testData)
        
        // Then
        let item = container.items[0]
        #expect(item.name == "binary")
        #expect(item.contentType == nil)
        #expect(item.contentLength == 4)
    }
    
    @Test("Adds a file from Data")
    func testAddFileFromData() {
        // Given
        let container = MultipartDataContainer()
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        
        // When
        container.addFile(name: "photo", filename: "image.jpg", contentType: .jpeg, data: imageData)
        
        // Then
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "photo")
        #expect(item.filename == "image.jpg")
        #expect(item.contentType == .jpeg)
        #expect(item.contentLength == 4)
    }
    
    @Test("Adds a file from a URL")
    func testAddFileFromURL() throws {
        // Given
        let container = MultipartDataContainer()
        let tempURL = createTempFile(content: "file content")
        
        // When
        try container.addFile(name: "document", filename: "test.txt", contentType: .plainText, fileURL: tempURL)
        
        // Then
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "document")
        #expect(item.filename == "test.txt")
        #expect(item.contentType == .plainText)
        #expect(item.contentLength == 12) // "file content".count
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Adds a file from a URL without a filename")
    func testAddFileFromURLWithoutFilename() throws {
        // Given
        let container = MultipartDataContainer()
        let tempURL = createTempFile(content: "test", filename: "document.pdf")
        
        // When
        try container.addFile(name: "upload", fileURL: tempURL)
        
        // Then
        let item = container.items[0]
        #expect(item.name == "upload")
        #expect(item.filename == "document.pdf") // Taken from the URL
        #expect(item.contentType == .pdf) // Determined by the extension
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Throws an error for a nonexistent file")
    func testAddFileFromNonExistentURL() {
        // Given
        let container = MultipartDataContainer()
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.txt")
        
        // When/Then
        #expect(throws: MultipartError.fileNotFound(nonExistentURL)) {
            try container.addFile(name: "missing", fileURL: nonExistentURL)
        }
        #expect(container.count == 0)
    }
    
    @Test("Throws an error when adding a directory as a file")
    func testAddDirectoryAsFile() throws {
        // Given
        let container = MultipartDataContainer()
        let tempDir = createTempDirectory()
        
        // When/Then
        #expect(throws: MultipartError.urlIsDirectory(tempDir)) {
            try container.addFile(name: "dir", fileURL: tempDir)
        }
        #expect(container.count == 0)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("Adds a data stream")
    func testAddStream() {
        // Given
        let container = MultipartDataContainer()
        let data = "stream data".data(using: .utf8)!
        let stream = InputStream(data: data)
        
        // When
        container.addStream(
            name: "stream",
            filename: "data.bin",
            contentType: .custom("application/octet-stream"),
            stream: stream,
            contentLength: 100
        )
        
        // Then
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "stream")
        #expect(item.filename == "data.bin")
        #expect(item.contentType == .custom("application/octet-stream"))
        #expect(item.contentLength == 100) // The specified size, not the actual one
    }
    
    @Test("Adds an arbitrary item")
    func testAddItem() {
        // Given
        let container = MultipartDataContainer()
        let customItem = MultipartItem.text(name: "custom", value: "value")
        
        // When
        container.addItem(customItem)
        
        // Then
        #expect(container.count == 1)
        #expect(container.items[0].name == "custom")
    }
    
    @Test("Calculates the total content length")
    func testContentLength() {
        // Given
        let container = MultipartDataContainer()
        
        // When
        container.addText(name: "field1", value: "12345") // 5 bytes
        container.addData(name: "field2", data: Data([1, 2, 3])) // 3 bytes
        container.addFile(name: "field3", filename: "test.txt", data: Data([4, 5, 6, 7])) // 4 bytes
        
        // Then
        #expect(container.contentLength == 12) // 5 + 3 + 4
    }
    
    @Test("Supports method chaining")
    func testFluentAPI() {
        // Given
        let container = MultipartDataContainer()
        
        // When
        let result = container
            .addText(name: "name", value: "John")
            .addData(name: "data", data: Data([1, 2, 3]))
            .addFile(name: "file", filename: "test.txt", data: Data([4, 5]))
        
        // Then
        #expect(result === container)
        #expect(container.count == 3)
        #expect(container.items[0].name == "name")
        #expect(container.items[1].name == "data")
        #expect(container.items[2].name == "file")
    }
}

// MARK: - Test Helpers

extension MultipartDataContainerTests {
    
    private func createTempFile(content: String, filename: String = "temp.txt") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try! content.data(using: .utf8)!.write(to: fileURL)
        return fileURL
    }
    
    private func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dirURL = tempDir.appendingPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }
}
