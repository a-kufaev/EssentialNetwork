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
@testable import EssentialNetworkTesting
import Foundation
import Testing

/// Unit tests for `InputStreamReader`.
///
/// Verifies correct reading of data from an InputStream, error handling, buffer behavior, and interaction with mocks.
struct InputStreamReaderTests {
    
    @Test("Successfully reads data from the stream")
    func testReadSuccess() throws {
        // Given
        
        let string = String(repeating: "A", count: 2048)
        let data = try #require(string.data(using: .utf8))
        let bufferSize = 1024
        let reader = InputStreamReader(bufferSize: bufferSize)
        let mock = InputStreamMock()
        mock.customStatus = .open
        mock.hasBytes = true
        var offset = 0
        mock.readHandler = { buffer, len in
            let remaining = data.count - offset
            let toRead = min(len, remaining)
            if toRead > 0 {
                data.copyBytes(to: buffer, from: offset ..< (offset + toRead))
                offset += toRead
                return toRead
            } else {
                mock.hasBytes = false
                return 0
            }
        }
        
        // When
        
        let result = try reader.read(mock, expectedLength: UInt64(data.count))
        
        // Then
        
        #expect(result == data)
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
        #expect(mock.readCallCount >= 2)
    }

    @Test("Stream open failure")
    func testOpenFailed() {
        // Given
        
        let mock = InputStreamMock()
        mock.customStatus = .error
        let reader = InputStreamReader()
        
        // When/Then
        
        #expect(throws: InputStreamReaderError.openFailed(status: .error)) {
            _ = try reader.read(mock, expectedLength: 0)
        }
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Stream error (streamError)")
    func testStreamError() {
        // Given
        
        let mock = InputStreamMock()
        mock.customStatus = .open
        let error = NSError(domain: "Test", code: 42)
        mock.customError = error
        mock.hasBytes = true
        mock.readHandler = { _, _ in
            mock.hasBytes = false
            return 1
        }
        let reader = InputStreamReader()
        
        // When/Then
        
        #expect(throws: InputStreamReaderError.streamError(error)) {
            _ = try reader.read(mock, expectedLength: 0)
        }
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Read error (read < 0)")
    func testReadFailed() {
        // Given
        
        let mock = InputStreamMock()
        mock.customStatus = .open
        mock.hasBytes = true
        var called = false
        mock.readHandler = { _, _ in
            if !called {
                called = true
                mock.hasBytes = false
                return -2
            }
            return 0
        }
        let reader = InputStreamReader()
        
        // When/Then
        
        #expect(throws: InputStreamReaderError.readFailed(bytesRead: -2)) {
            _ = try reader.read(mock, expectedLength: 0)
        }
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Data size mismatch")
    func testSizeMismatch() throws {
        // Given
        
        let string = "12345"
        let data = try #require(string.data(using: .utf8))
        let mock = InputStreamMock()
        mock.customStatus = .open
        mock.hasBytes = true
        var offset = 0
        mock.readHandler = { buffer, len in
            let remaining = data.count - offset
            let toRead = min(len, remaining)
            if toRead > 0 {
                data.copyBytes(to: buffer, from: offset ..< (offset + toRead))
                offset += toRead
                if offset == data.count {
                    mock.hasBytes = false
                }
                return toRead
            } else {
                mock.hasBytes = false
                return 0
            }
        }
        let reader = InputStreamReader()
        
        // When/Then
        
        #expect(throws: InputStreamReaderError.sizeMismatch(expected: 10, actual: data.count)) {
            _ = try reader.read(mock, expectedLength: 10)
        }
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Reading an empty stream returns empty Data without errors")
    func testReadEmptyStream() throws {
        // Given
        
        let mock = InputStreamMock()
        mock.customStatus = .open
        mock.hasBytes = false
        mock.readHandler = { _, _ in 0 }
        let reader = InputStreamReader()
        
        // When
        
        let result = try reader.read(mock, expectedLength: 0)
        
        // Then
        
        #expect(result.isEmpty)
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Reading with an error after partial data throws streamError")
    func testReadWithErrorAfterPartialData() {
        // Given
        
        let mock = InputStreamMock()
        mock.customStatus = .open
        let error = NSError(domain: "Test", code: 99)
        var call = 0
        mock.hasBytes = true
        mock.readHandler = { _, _ in
            call += 1
            if call == 1 {
                return 1 // Read a byte
            } else {
                mock.customError = error
                mock.hasBytes = false
                return 1
            }
        }
        let reader = InputStreamReader()
        
        // When/Then
        
        #expect(throws: InputStreamReaderError.streamError(error)) {
            _ = try reader.read(mock, expectedLength: 0)
        }
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }

    @Test("Reading via read without expectedLength returns all data without errors")
    func testReadWithoutExpectedLength() throws {
        // Given
        
        let string = "TestData"
        let data = try #require(string.data(using: .utf8))
        let mock = InputStreamMock()
        mock.customStatus = .open
        mock.hasBytes = true
        var offset = 0
        mock.readHandler = { buffer, len in
            let remaining = data.count - offset
            let toRead = min(len, remaining)
            if toRead > 0 {
                data.copyBytes(to: buffer, from: offset ..< (offset + toRead))
                offset += toRead
                if offset == data.count {
                    mock.hasBytes = false
                }
                return toRead
            } else {
                mock.hasBytes = false
                return 0
            }
        }
        let reader = InputStreamReader()
        
        // When
        
        let result = try reader.read(mock)
        
        // Then
        
        #expect(result == data)
        #expect(mock.openCallCount == 1)
        #expect(mock.closeCallCount == 1)
    }
}
