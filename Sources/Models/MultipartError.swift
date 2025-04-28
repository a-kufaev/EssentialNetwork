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

/// Errors that occur while working with multipart data.
public enum MultipartError: Error, Sendable {
    
    /// Failed to create an `InputStream` for the given URL.
    case inputStreamCreationFailed(for: URL)
    
    /// The URL is not a file URL.
    case invalidFileURL(URL)
    
    /// The file does not exist.
    case fileNotFound(URL)
    
    /// The URL points to a directory rather than a file.
    case urlIsDirectory(URL)
    
    /// Failed to encode the multipart data.
    case encodingFailed(Error)
    
    /// Invalid multipart data boundary.
    case invalidBoundary(boundary: String, reason: String)
    
    /// Errors related to reading data from an `InputStream`.
    case inputStreamReaderError(InputStreamReaderError)
}

// MARK: - Extensions

extension MultipartError {
    
    /// The underlying error, if any.
    public var underlyingError: (any Error)? {
        switch self {
        case .inputStreamCreationFailed, .invalidFileURL, .fileNotFound, .urlIsDirectory, .invalidBoundary:
            nil
        case let .encodingFailed(error):
            error
        case let .inputStreamReaderError(inputStreamReaderError):
            inputStreamReaderError.underlyingError
        }
    }
}
