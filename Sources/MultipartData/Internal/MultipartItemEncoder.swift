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

/// An encoder for individual multipart data parts.
///
/// Responsible for encoding a single multipart data part into the multipart/form-data format:
/// - Adding the boundary
/// - Building the part headers
/// - Encoding the part data
struct MultipartItemEncoder: AnyMultipartItemEncoder {
    
    /// The reader for data from an InputStream.
    private let streamReader: AnyInputStreamReader
    
    /// Creates an encoder with the specified buffer size.
    ///
    /// - Parameter bufferSize: the buffer size for reading streams (default is 1024)
    init(bufferSize: Int = .bufferSize) {
        streamReader = InputStreamReader(bufferSize: bufferSize)
    }

    // periphery:ignore - Intended for future use
    /// Creates an encoder with the specified reader.
    ///
    /// - Parameter streamReader: the reader for data from an InputStream
    init(streamReader: AnyInputStreamReader) {
        self.streamReader = streamReader
    }
    
    /// Encodes an individual multipart data part.
    ///
    /// - Parameters:
    ///   - item: a multipart data part
    ///   - boundary: the boundary used to separate parts
    /// - Returns: the encoded part data
    /// - Throws: `MultipartError` in case of an encoding error
    func encode(_ item: MultipartItem, boundary: String) throws(MultipartError) -> Data {
        var data = Data()
        
        // Add the boundary
        data.append("--\(boundary)\(String.newLine)".safeTextData)
        
        // Add the part headers
        data.append(makeHeaders(for: item))
        data.append(String.newLine.safeTextData)
        
        // Add the part data
        let inputStream = try item.dataSource.createInputStream()
        let itemData = try readItemData(from: inputStream, expectedLength: item.contentLength)
        data.append(itemData)
        data.append(String.newLine.safeTextData)
        
        return data
    }
    
    /// Reads the part data, handling InputStreamReader errors.
    ///
    /// - Parameters:
    ///   - inputStream: the stream to read from
    ///   - expectedLength: the expected data size
    /// - Returns: the read data
    /// - Throws: `MultipartError` in case of a read error
    private func readItemData(from inputStream: InputStream, expectedLength: UInt64) throws(MultipartError) -> Data {
        do {
            return try streamReader.read(inputStream, expectedLength: expectedLength)
        } catch {
            throw MultipartError.inputStreamReaderError(error)
        }
    }
    
    /// Creates the headers for a multipart data part.
    ///
    /// - Parameter item: a multipart data part
    /// - Returns: the header data in multipart format
    private func makeHeaders(for item: MultipartItem) -> Data {
        var headers: [HTTPHeader] = []
        
        // Build the Content-Disposition header
        var contentDispositionValue = "form-data; name=\"\(item.name)\""
        if let filename = item.filename {
            contentDispositionValue += "; filename=\"\(filename)\""
        }
        headers.append(.contentDisposition(contentDispositionValue))
        
        // Add the Content-Type if specified
        if let contentType = item.contentType {
            headers.append(.contentType(contentType.rawValue))
        }
        
        // Convert the headers into a string
        return headers
            .map { "\($0.name): \($0.value)\(String.newLine)" }
            .joined()
            .safeTextData
    }
}

// MARK: - Helper Extensions

extension String {
    
    /// The newline character for the multipart format.
    fileprivate static let newLine: String = "\r\n"
    
    /// Safe conversion of a string to Data.
    fileprivate var safeTextData: Data {
        // swiftlint:disable force_unwrapping
        data(using: .utf8)!
        // swiftlint:enable force_unwrapping
    }
}

extension Int {
    
    /// The buffer size for reading from an InputStream.
    ///
    /// 1024 is the "sweet spot" for multipart requests
    fileprivate static let bufferSize = 1024
}
