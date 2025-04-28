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

/// A single part of multipart data.
///
/// Each part contains:
/// - field name (name)
/// - optional file name (filename)
/// - optional MIME type (contentType)
/// - data source (dataSource)
public struct MultipartItem: Sendable {
    
    /// The form field name.
    public let name: String
    
    /// The file name (used for file parts).
    public let filename: String?
    
    /// The content MIME type (optional).
    public let contentType: MIMEType?
    
    /// The data source.
    public let dataSource: MultipartDataSource
    
    /// The data size in bytes.
    public var contentLength: UInt64 {
        dataSource.contentLength
    }
    
    /// Creates a part with text data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - value: the text value
    /// - Returns: a MultipartItem with text data
    public static func text(name: String, value: String) -> MultipartItem {
        let data = value.data(using: .utf8) ?? Data()
        return MultipartItem(
            name: name,
            filename: nil,
            contentType: .plainText,
            dataSource: data
        )
    }
    
    /// Creates a part with arbitrary data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - data: the data
    ///   - contentType: an optional MIME type
    /// - Returns: a MultipartItem with data
    public static func data(
        name: String,
        data: Data,
        contentType: MIMEType? = nil
    ) -> MultipartItem {
        MultipartItem(
            name: name,
            filename: nil,
            contentType: contentType,
            dataSource: data
        )
    }
    
    /// Creates a part with file data from Data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: the file name
    ///   - contentType: an optional file MIME type
    ///   - data: the file data
    /// - Returns: a MultipartItem with file data
    public static func file(
        name: String,
        filename: String,
        contentType: MIMEType? = nil,
        data: Data
    ) -> MultipartItem {
        MultipartItem(
            name: name,
            filename: filename,
            contentType: contentType,
            dataSource: data
        )
    }
    
    /// Creates a part with file data from a URL.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: an optional file name
    ///   - contentType: an optional file MIME type
    ///   - fileURL: the file URL
    /// - Returns: a MultipartItem with file data
    /// - Throws: MultipartError if the file is unavailable
    public static func file(
        name: String,
        filename: String? = nil,
        contentType: MIMEType? = nil,
        fileURL: URL
    ) throws(MultipartError) -> MultipartItem {
        // Verify that this is a file URL
        guard fileURL.isFileURL else {
            throw MultipartError.invalidFileURL(fileURL)
        }
        
        // Verify that the file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw MultipartError.fileNotFound(fileURL)
        }
        
        // Verify that it is not a directory
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            throw MultipartError.urlIsDirectory(fileURL)
        }
        
        let finalFilename = filename ?? fileURL.lastPathComponent
        let finalContentType: MIMEType?
        
        if let contentType {
            finalContentType = contentType
        } else {
            let pathExtension = fileURL.pathExtension
            finalContentType = MIMEType.from(pathExtension: pathExtension)
        }
        
        return MultipartItem(
            name: name,
            filename: finalFilename,
            contentType: finalContentType,
            dataSource: fileURL
        )
    }
    
    /// Creates a part with data from an InputStream.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: an optional file name
    ///   - contentType: an optional MIME type
    ///   - stream: an InputStream with the data
    ///   - contentLength: the data size in bytes (REQUIRED)
    /// - Returns: a MultipartItem with streamed data
    public static func stream(
        name: String,
        filename: String? = nil,
        contentType: MIMEType? = nil,
        stream: InputStream,
        contentLength: UInt64
    ) -> MultipartItem {
        // Create a wrapper for the InputStream with the specified size
        let dataSource = StreamDataSource(stream: stream, contentLength: contentLength)
        
        return MultipartItem(
            name: name,
            filename: filename,
            contentType: contentType,
            dataSource: dataSource
        )
    }
    
    /// Creates a part with arbitrary data.
    ///
    /// - Parameters:
    ///   - name: the field name
    ///   - filename: an optional file name
    ///   - contentType: an optional MIME type
    ///   - dataSource: the data source
    /// - Returns: a MultipartItem
    public init(
        name: String,
        filename: String?,
        contentType: MIMEType?,
        dataSource: MultipartDataSource
    ) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.dataSource = dataSource
    }
}
