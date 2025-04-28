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

import Foundation

/// A reader for data from an `InputStream`.
///
/// Responsible for safely reading data from an `InputStream` with validation:
/// - Opening and closing the stream
/// - Checking the stream state
/// - Buffered reading
/// - Validating the data size
///
/// Buffered reading provides:
/// - Efficiency: fewer system calls (1 call per 1024 bytes instead of 1024 calls of 1 byte each)
/// - Performance: optimal use of CPU and memory
/// - Scalability: works well with files of any size
public struct InputStreamReader: AnyInputStreamReader {
    
    /// The buffer size used for reading.
    private let bufferSize: Int
    
    /// Creates a reader with the given buffer size.
    ///
    /// - Parameter bufferSize: the buffer size in bytes (defaults to 1024)
    public init(bufferSize: Int = 1024) {
        self.bufferSize = bufferSize
    }
    
    /// Reads data from an `InputStream`.
    ///
    /// - Parameters:
    ///   - inputStream: the stream to read from
    ///   - expectedLength: the expected data size
    /// - Returns: the data that was read
    /// - Throws: `InputStreamReaderError` if reading fails
    public func read(_ inputStream: InputStream, expectedLength: UInt64) throws(InputStreamReaderError) -> Data {
        // Open the stream
        inputStream.open()
        defer { inputStream.close() }
        
        // Check the stream state after opening
        guard inputStream.streamStatus == .open else {
            throw InputStreamReaderError.openFailed(status: inputStream.streamStatus)
        }
        
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        var bytesRead = 0
        
        // Read data from the stream
        while inputStream.hasBytesAvailable {
            let bytesReadThisTime = inputStream.read(buffer, maxLength: bufferSize)
            
            // Check for stream errors
            if let streamError = inputStream.streamError {
                throw InputStreamReaderError.streamError(streamError)
            }
            
            if bytesReadThisTime > 0 {
                data.append(buffer, count: bytesReadThisTime)
                bytesRead += bytesReadThisTime
            } else if bytesReadThisTime == 0 {
                // End of stream reached
                break
            } else {
                // A negative value indicates an error
                throw InputStreamReaderError.readFailed(bytesRead: bytesReadThisTime)
            }
        }
        
        // Validate the data size
        if expectedLength > 0, UInt64(bytesRead) != expectedLength {
            throw InputStreamReaderError.sizeMismatch(expected: expectedLength, actual: bytesRead)
        }
        
        return data
    }
    
    /// Reads data from an `InputStream` without size validation.
    ///
    /// - Parameter inputStream: the stream to read from
    /// - Returns: the data that was read
    /// - Throws: `InputStreamReaderError` if reading fails
    public func read(_ inputStream: InputStream) throws(InputStreamReaderError) -> Data {
        try read(inputStream, expectedLength: 0)
    }
}
