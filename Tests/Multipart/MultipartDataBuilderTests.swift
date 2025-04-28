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

/// Unit tests for `MultipartDataBuilder`.
///
/// Verifies the fluent API for creating multipart containers, method chaining, adding various data types,
/// and correct construction of the resulting container.
struct MultipartDataBuilderTests {
    
    @Test("Creates an empty builder")
    func testEmptyBuilder() {
        // Given
        let builder = MultipartDataBuilder()
        
        // When
        let container = builder.build()
        
        // Then
        #expect(container.isEmpty == true)
        #expect(container.count == 0)
    }
    
    @Test("Adds a text field")
    func testAddText() {
        // Given
        let builder = MultipartDataBuilder()
        
        // When
        let result = builder.addText(name: "username", value: "john_doe")
        let container = builder.build()
        
        // Then
        #expect(result === builder) // Verify the fluent API
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "username")
        #expect(item.filename == nil)
        #expect(item.contentType == .plainText)
    }
    
    @Test("Adds arbitrary data")
    func testAddData() {
        // Given
        let builder = MultipartDataBuilder()
        let testData = "test data".data(using: .utf8)!
        
        // When
        let result = builder.addData(name: "payload", data: testData, contentType: .json)
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "payload")
        #expect(item.contentType == .json)
        #expect(item.contentLength == UInt64(testData.count))
    }
    
    @Test("Adds data without a contentType")
    func testAddDataWithoutContentType() {
        // Given
        let builder = MultipartDataBuilder()
        let data = Data([1, 2, 3])
        
        // When
        builder.addData(name: "binary", data: data)
        let container = builder.build()
        
        // Then
        let item = container.items[0]
        #expect(item.name == "binary")
        #expect(item.contentType == nil)
    }
    
    @Test("Adds a file from Data")
    func testAddFileFromData() {
        // Given
        let builder = MultipartDataBuilder()
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        
        // When
        let result = builder.addFile(name: "photo", filename: "image.jpg", contentType: .jpeg, data: imageData)
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "photo")
        #expect(item.filename == "image.jpg")
        #expect(item.contentType == .jpeg)
    }
    
    @Test("Adds a file from Data without a contentType")
    func testAddFileFromDataWithoutContentType() {
        // Given
        let builder = MultipartDataBuilder()
        let data = Data([1, 2, 3, 4])
        
        // When
        builder.addFile(name: "upload", filename: "data.bin", data: data)
        let container = builder.build()
        
        // Then
        let item = container.items[0]
        #expect(item.name == "upload")
        #expect(item.filename == "data.bin")
        #expect(item.contentType == nil)
    }
    
    @Test("Adds a file from a URL")
    func testAddFileFromURL() throws {
        // Given
        let builder = MultipartDataBuilder()
        let tempURL = createTempFile(content: "file content", filename: "document.txt")
        
        // When
        let result = try builder.addFile(
            name: "document",
            filename: "custom.txt",
            contentType: .plainText,
            fileURL: tempURL
        )
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "document")
        #expect(item.filename == "custom.txt")
        #expect(item.contentType == .plainText)
        #expect(item.contentLength == 12) // "file content".count
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Adds a file from a URL with auto-detected parameters")
    func testAddFileFromURLWithAutoDetection() throws {
        // Given
        let builder = MultipartDataBuilder()
        let tempURL = createTempFile(content: "test", filename: "report.pdf")
        
        // When
        try builder.addFile(name: "upload", fileURL: tempURL)
        let container = builder.build()
        
        // Then
        let item = container.items[0]
        #expect(item.name == "upload")
        #expect(item.filename == "report.pdf") // From the URL
        #expect(item.contentType == .pdf) // By the extension
        #expect(item.contentLength == 4) // "test".count
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Throws an error for a nonexistent file")
    func testAddFileFromNonExistentURL() {
        // Given
        let builder = MultipartDataBuilder()
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.txt")
        
        // When/Then
        #expect(throws: MultipartError.fileNotFound(nonExistentURL)) {
            try builder.addFile(name: "missing", fileURL: nonExistentURL)
        }
        
        let container = builder.build()
        #expect(container.count == 0)
    }
    
    @Test("Adds a data stream")
    func testAddStream() {
        // Given
        let builder = MultipartDataBuilder()
        let data = "stream content".data(using: .utf8)!
        let stream = InputStream(data: data)
        
        // When
        let result = builder.addStream(
            name: "upload",
            filename: "data.bin",
            contentType: .custom("application/octet-stream"),
            stream: stream,
            contentLength: 1024
        )
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 1)
        
        let item = container.items[0]
        #expect(item.name == "upload")
        #expect(item.filename == "data.bin")
        #expect(item.contentType == .custom("application/octet-stream"))
        #expect(item.contentLength == 1024)
    }
    
    @Test("Adds a stream without filename and contentType")
    func testAddStreamMinimal() {
        // Given
        let builder = MultipartDataBuilder()
        let stream = InputStream(data: Data())
        
        // When
        builder.addStream(name: "stream", stream: stream, contentLength: 500)
        let container = builder.build()
        
        // Then
        let item = container.items[0]
        #expect(item.name == "stream")
        #expect(item.filename == nil)
        #expect(item.contentType == nil)
        #expect(item.contentLength == 500)
    }
    
    @Test("Adds an arbitrary item")
    func testAddItem() {
        // Given
        let builder = MultipartDataBuilder()
        let customItem = MultipartItem.text(name: "custom", value: "value")
        
        // When
        let result = builder.addItem(customItem)
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 1)
        #expect(container.items[0].name == "custom")
    }
    
    @Test("Supports a complex method chain")
    func testComplexFluentAPI() throws {
        // Given
        let builder = MultipartDataBuilder()
        let tempURL = createTempFile(content: "file", filename: "test.txt")
        let stream = InputStream(data: Data([1, 2, 3]))
        
        // When
        let result = try builder
            .addText(name: "name", value: "John Doe")
            .addData(name: "metadata", data: Data([0xFF, 0xFE]), contentType: .json)
            .addFile(name: "avatar", filename: "photo.jpg", contentType: .jpeg, data: Data([1, 2, 3, 4]))
            .addFile(name: "document", fileURL: tempURL)
            .addStream(name: "upload", stream: stream, contentLength: 100)
        
        let container = builder.build()
        
        // Then
        #expect(result === builder)
        #expect(container.count == 5)
        
        // Verify the order and types of items
        #expect(container.items[0].name == "name")
        #expect(container.items[1].name == "metadata")
        #expect(container.items[2].name == "avatar")
        #expect(container.items[3].name == "document")
        #expect(container.items[4].name == "upload")
        
        // Verify the total size
        let expectedSize: UInt64 = 8 + 2 + 4 + 4 + 100 // name + metadata + avatar + document + upload
        #expect(container.contentLength == expectedSize)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
}

// MARK: - Test Helpers

extension MultipartDataBuilderTests {
    
    private func createTempFile(content: String, filename: String = "temp.txt") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try! content.data(using: .utf8)!.write(to: fileURL)
        return fileURL
    }
}
