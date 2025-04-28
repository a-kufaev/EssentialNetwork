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

/// A builder for creating a MultipartDataContainer with a fluent API.
///
/// Lets you build a container with a chain of calls:
/// ```swift
/// let container = MultipartDataBuilder()
///     .addText(name: "username", value: "john_doe")
///     .addFile(name: "image", filename: "photo.jpg", contentType: .jpeg, data: imageData)
///     .build()
/// ```
public final class MultipartDataBuilder: Sendable {
    
    private let container: MultipartDataContainer
    
    /// Creates a new builder.
    public init() {
        container = MultipartDataContainer()
    }
    
    /// Adds a text field.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - value: the text value
    /// - Returns: self for call chaining
    @discardableResult
    public func addText(name: String, value: String) -> Self {
        container.addText(name: name, value: value)
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
        container.addData(name: name, data: data, contentType: contentType)
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
        container.addFile(name: name, filename: filename, contentType: contentType, data: data)
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
        try container.addFile(name: name, filename: filename, contentType: contentType, fileURL: fileURL)
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
        container.addStream(
            name: name,
            filename: filename,
            contentType: contentType,
            stream: stream,
            contentLength: contentLength
        )
        return self
    }
    
    /// Adds an arbitrary part.
    ///
    /// - Parameter item: a multipart data part
    /// - Returns: self for call chaining
    @discardableResult
    public func addItem(_ item: MultipartItem) -> Self {
        container.addItem(item)
        return self
    }
    
    /// Creates a MultipartDataContainer.
    ///
    /// - Returns: a ready container with multipart data
    public func build() -> MultipartDataContainer {
        container
    }
}
