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

// TODO: Disable swiftlint because CI fails with the identifier_name lint error
// swiftlint:disable all

import Foundation

/// A data source for a multipart part.
///
/// Supports various types of data sources:
/// - Data (for small in-memory data)
/// - URL (for files)
/// - InputStream (for large files and streams)
public protocol MultipartDataSource: Sendable {
    
    /// The data size in bytes.
    var contentLength: UInt64 { get }
    
    /// Creates an InputStream for reading the data.
    ///
    /// - Returns: an InputStream for reading the data
    /// - Throws: `MultipartError` when creating the stream
    func createInputStream() throws(MultipartError) -> InputStream
}

// MARK: - MultipartDataSource

extension Data: MultipartDataSource {
    
    public var contentLength: UInt64 {
        UInt64(count)
    }
    
    public func createInputStream() throws(MultipartError) -> InputStream {
        InputStream(data: self)
    }
}

// MARK: - MultipartDataSource

extension URL: MultipartDataSource {
    
    public var contentLength: UInt64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            return 0
        }
    }
    
    public func createInputStream() throws(MultipartError) -> InputStream {
        guard let stream = InputStream(url: self) else {
            throw MultipartError.inputStreamCreationFailed(for: self)
        }
        return stream
    }
}

// MARK: - @unchecked @retroactive Sendable

extension InputStream: @unchecked @retroactive Sendable {}

/// A wrapper for an InputStream with a specified size.
///
/// Used to pass an InputStream with a known data size.
struct StreamDataSource: MultipartDataSource {
    
    /// The data stream.
    let stream: InputStream
    
    /// The data size in bytes.
    let contentLength: UInt64
    
    /// Creates an InputStream for reading the data.
    ///
    /// - Returns: the original stream
    /// - Throws: does not throw any errors
    func createInputStream() throws(MultipartError) -> InputStream {
        stream
    }
}

// swiftlint:enable all
