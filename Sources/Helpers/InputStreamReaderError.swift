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

/// Errors that occur while reading data from an `InputStream`.
public enum InputStreamReaderError: Error, Sendable {
    
    /// Failed to open the stream.
    /// - Parameter status: the stream status after the open attempt
    case openFailed(status: Stream.Status)
    
    /// Failed to read data from the stream.
    /// - Parameter bytesRead: the number of bytes read (a negative value)
    case readFailed(bytesRead: Int)
    
    /// Mismatch between the expected and actual data size.
    /// - Parameters:
    ///   - expected: the expected size in bytes
    ///   - actual: the actual size in bytes
    case sizeMismatch(expected: UInt64, actual: Int)
    
    /// A stream error (for example, network problems).
    /// - Parameter error: the underlying stream error
    case streamError(Error)
}

// MARK: - Extensions

extension InputStreamReaderError {
    
    /// The underlying error, if any.
    public var underlyingError: (any Error)? {
        switch self {
        case .openFailed, .readFailed, .sizeMismatch:
            nil
        case let .streamError(error):
            error
        }
    }
}
