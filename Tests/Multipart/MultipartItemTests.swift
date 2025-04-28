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

/// Unit tests for `MultipartItem`.
///
/// Verifies the creation of various multipart item types, file validation, error handling,
/// and correct determination of MIME types.
struct MultipartItemTests {
    
    @Test("Creates a text item")
    func testTextItem() {
        // Given/When
        let item = MultipartItem.text(name: "message", value: "Hello, World!")
        
        // Then
        #expect(item.name == "message")
        #expect(item.filename == nil)
        #expect(item.contentType == .plainText)
        #expect(item.contentLength == 13) // "Hello, World!".utf8.count
    }
    
    @Test("Creates a text item with an empty value")
    func testTextItemWithEmptyValue() {
        // Given/When
        let item = MultipartItem.text(name: "empty", value: "")
        
        // Then
        #expect(item.name == "empty")
        #expect(item.contentLength == 0)
        #expect(item.contentType == .plainText)
    }
    
    @Test("Creates an item with data")
    func testDataItem() {
        // Given
        let testData = Data([1, 2, 3, 4, 5])
        
        // When
        let item = MultipartItem.data(name: "binary", data: testData, contentType: .custom("application/octet-stream"))
        
        // Then
        #expect(item.name == "binary")
        #expect(item.filename == nil)
        #expect(item.contentType == .custom("application/octet-stream"))
        #expect(item.contentLength == 5)
    }
    
    @Test("Creates an item with data without a contentType")
    func testDataItemWithoutContentType() {
        // Given
        let testData = Data([0xFF, 0xFE])
        
        // When
        let item = MultipartItem.data(name: "raw", data: testData)
        
        // Then
        #expect(item.name == "raw")
        #expect(item.contentType == nil)
        #expect(item.contentLength == 2)
    }
    
    @Test("Creates a file item from Data")
    func testFileItemFromData() {
        // Given
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        
        // When
        let item = MultipartItem.file(name: "avatar", filename: "photo.jpg", contentType: .jpeg, data: imageData)
        
        // Then
        #expect(item.name == "avatar")
        #expect(item.filename == "photo.jpg")
        #expect(item.contentType == .jpeg)
        #expect(item.contentLength == 4)
    }
    
    @Test("Creates a file item from Data without a contentType")
    func testFileItemFromDataWithoutContentType() {
        // Given
        let data = Data([1, 2, 3])
        
        // When
        let item = MultipartItem.file(name: "file", filename: "data.bin", data: data)
        
        // Then
        #expect(item.name == "file")
        #expect(item.filename == "data.bin")
        #expect(item.contentType == nil)
        #expect(item.contentLength == 3)
    }
    
    @Test("Creates a file item from a URL")
    func testFileItemFromURL() throws {
        // Given
        let tempURL = createTempFile(content: "file content", filename: "document.txt")
        
        // When
        let item = try MultipartItem.file(
            name: "upload",
            filename: "custom.txt",
            contentType: .plainText,
            fileURL: tempURL
        )
        
        // Then
        #expect(item.name == "upload")
        #expect(item.filename == "custom.txt")
        #expect(item.contentType == .plainText)
        #expect(item.contentLength == 12) // "file content".count
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Creates a file item from a URL without a filename")
    func testFileItemFromURLWithoutFilename() throws {
        // Given
        let tempURL = createTempFile(content: "test", filename: "report.pdf")
        
        // When
        let item = try MultipartItem.file(name: "document", fileURL: tempURL)
        
        // Then
        #expect(item.name == "document")
        #expect(item.filename == "report.pdf") // Taken from the URL
        #expect(item.contentType == .pdf) // Determined by the extension
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test("Throws an error for a nonexistent file")
    func testFileNotFoundError() {
        // Given
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.txt")
        
        // When/Then
        #expect(throws: MultipartError.fileNotFound(nonExistentURL)) {
            _ = try MultipartItem.file(name: "missing", fileURL: nonExistentURL)
        }
    }
    
    @Test("Throws an error for a non-file URL")
    func testInvalidFileURLError() throws {
        // Given
        let httpURL = try #require(URL(string: "https://example.com/file.txt"))
        
        // When/Then
        #expect(throws: MultipartError.invalidFileURL(httpURL)) {
            _ = try MultipartItem.file(name: "remote", fileURL: httpURL)
        }
    }
    
    @Test("Throws an error when trying to use a directory as a file")
    func testDirectoryAsFileError() throws {
        // Given
        let tempDir = createTempDirectory()
        
        // When/Then
        #expect(throws: MultipartError.urlIsDirectory(tempDir)) {
            _ = try MultipartItem.file(name: "dir", fileURL: tempDir)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("Creates an item with a stream")
    func testStreamItem() {
        // Given
        let data = "stream content".data(using: .utf8)!
        let stream = InputStream(data: data)
        
        // When
        let item = MultipartItem.stream(
            name: "upload",
            filename: "data.bin",
            contentType: .custom("application/octet-stream"),
            stream: stream,
            contentLength: 1024
        )
        
        // Then
        #expect(item.name == "upload")
        #expect(item.filename == "data.bin")
        #expect(item.contentType == .custom("application/octet-stream"))
        #expect(item.contentLength == 1024) // The specified size
    }
    
    @Test("Creates an item with a stream without filename and contentType")
    func testStreamItemMinimal() {
        // Given
        let stream = InputStream(data: Data())
        
        // When
        let item = MultipartItem.stream(name: "stream", stream: stream, contentLength: 500)
        
        // Then
        #expect(item.name == "stream")
        #expect(item.filename == nil)
        #expect(item.contentType == nil)
        #expect(item.contentLength == 500)
    }
}

// MARK: - Test Helpers

extension MultipartItemTests {
    
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
