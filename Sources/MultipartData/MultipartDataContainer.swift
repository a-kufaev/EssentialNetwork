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

/// A container for collecting multipart data.
///
/// Provides a convenient API for adding various types of data:
/// - text fields
/// - files (from Data, URL, InputStream)
/// - arbitrary data
public final class MultipartDataContainer: Sendable {
    
    /// The multipart data parts.
    public private(set) nonisolated(unsafe) var items: [MultipartItem] = []
    
    /// Checks whether the container is empty.
    ///
    /// - Returns: true if the container is empty
    public var isEmpty: Bool {
        items.isEmpty
    }
    
    /// The number of parts in the container.
    public var count: Int {
        items.count
    }
    
    /// The total size of all data parts (excluding boundaries and headers).
    ///
    /// Used to compute the Content-Length header.
    public var contentLength: UInt64 {
        items.reduce(0) { $0 + $1.contentLength }
    }
    
    /// Creates an empty container.
    public init() {}
    
    /// Adds a text field.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - value: the text value
    /// - Returns: self for call chaining
    @discardableResult
    public func addText(name: String, value: String) -> Self {
        let item = MultipartItem.text(name: name, value: value)
        items.append(item)
        return self
    }
    
    /// Adds arbitrary data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - data: the data
    ///   - contentType: an optional MIME type
    /// - Returns: self for call chaining
    @discardableResult
    public func addData(
        name: String,
        data: Data,
        contentType: MIMEType? = nil
    ) -> Self {
        let item = MultipartItem.data(name: name, data: data, contentType: contentType)
        items.append(item)
        return self
    }
    
    /// Adds a file from Data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: the file name
    ///   - contentType: an optional file MIME type
    ///   - data: the file data
    /// - Returns: self for call chaining
    @discardableResult
    public func addFile(
        name: String,
        filename: String,
        contentType: MIMEType? = nil,
        data: Data
    ) -> Self {
        let item = MultipartItem.file(
            name: name,
            filename: filename,
            contentType: contentType,
            data: data
        )
        items.append(item)
        return self
    }
    
    /// Adds a file from a URL.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: an optional file name
    ///   - contentType: an optional MIME type
    ///   - fileURL: the file URL
    /// - Returns: self for call chaining
    /// - Throws: MultipartError if the file is unavailable
    @discardableResult
    public func addFile(
        name: String,
        filename: String? = nil,
        contentType: MIMEType? = nil,
        fileURL: URL
    ) throws -> Self {
        let item = try MultipartItem.file(
            name: name,
            filename: filename,
            contentType: contentType,
            fileURL: fileURL
        )
        items.append(item)
        return self
    }
    
    /// Adds data from an InputStream.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: an optional file name
    ///   - contentType: an optional MIME type
    ///   - stream: an InputStream with the data
    ///   - contentLength: the data size in bytes (REQUIRED)
    /// - Returns: self for call chaining
    @discardableResult
    public func addStream(
        name: String,
        filename: String? = nil,
        contentType: MIMEType? = nil,
        stream: InputStream,
        contentLength: UInt64
    ) -> Self {
        let item = MultipartItem.stream(
            name: name,
            filename: filename,
            contentType: contentType,
            stream: stream,
            contentLength: contentLength
        )
        items.append(item)
        return self
    }
    
    /// Adds an arbitrary part.
    ///
    /// - Parameter item: a multipart data part
    /// - Returns: self for call chaining
    @discardableResult
    public func addItem(_ item: MultipartItem) -> Self {
        items.append(item)
        return self
    }
}
