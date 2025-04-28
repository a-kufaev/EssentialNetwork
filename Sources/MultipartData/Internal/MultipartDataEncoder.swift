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

/// An encoder of multipart data into Data.
///
/// MultipartDataEncoder serializes a MultipartDataContainer into the multipart/form-data format:
/// 1. Generates a unique boundary
/// 2. Builds the request body according to RFC 7578
/// 3. Returns the encoded data
struct MultipartDataEncoder: AnyMultipartDataEncoder {
    
    /// The boundary generator for separating parts.
    private let boundaryGenerator: AnyMultipartBoundaryGenerator
    
    /// The part separator validator.
    private let boundaryValidator: AnyMultipartBoundaryValidator
    
    /// The encoder for individual parts.
    private let itemEncoder: AnyMultipartItemEncoder
    
    /// Creates an encoder with the specified boundary generator.
    ///
    /// - Parameters:
    ///   - boundaryGenerator: the boundary generator (the standard one is used by default)
    ///   - itemEncoder: the multipart part encoder (the standard one is used by default)
    init(
        boundaryGenerator: AnyMultipartBoundaryGenerator = MultipartBoundaryGenerator(),
        boundaryValidator: AnyMultipartBoundaryValidator = MultipartBoundaryValidator(),
        itemEncoder: AnyMultipartItemEncoder = MultipartItemEncoder(bufferSize: .bufferSize)
    ) {
        self.boundaryGenerator = boundaryGenerator
        self.boundaryValidator = boundaryValidator
        self.itemEncoder = itemEncoder
    }

    // periphery:ignore - Intended for future use
    /// Encodes multipart data into Data.
    ///
    /// - Parameter multipartData: the container with multipart data
    /// - Returns: the encoded data
    /// - Throws: `MultipartError` in case of an encoding error
    func encode(_ multipartData: MultipartDataContainer, boundary: String?) throws(MultipartError) -> Data {
        if let boundary { try boundaryValidator.validate(boundary) }
        let boundary = boundary ?? boundaryGenerator.generate()
        return try encodeMultipartData(multipartData, boundary: boundary)
    }
    
    /// Encodes multipart data into a URLRequest.
    ///
    /// - Parameters:
    ///   - urlRequest: the original request without an httpBody
    ///   - multipartData: the container with multipart data
    ///   - setContentLength: whether to set the Content-Length header
    /// - Returns: a URLRequest with a populated `httpBody` and a `Content-Type` header
    /// - Throws: `MultipartError` in case of an encoding error
    func encode(
        _ urlRequest: URLRequest,
        with multipartData: MultipartDataContainer,
        boundary: String?,
        setContentLength: Bool = false
    ) throws(MultipartError) -> (URLRequest, Data) {
        var urlRequest = urlRequest
        if let boundary { try boundaryValidator.validate(boundary) }
        let boundary = boundary ?? boundaryGenerator.generate()
        
        // Encode the data
        let data = try encodeMultipartData(multipartData, boundary: boundary)
        
        // Set the Content-Type header
        urlRequest.setHeader(.contentType("multipart/form-data; boundary=\(boundary)"))
        
        // Optionally set the Content-Length
        if setContentLength {
            urlRequest.setHeader(.contentLength("\(data.count)"))
        }
        
        return (urlRequest, data)
    }
}

// MARK: - Private Methods

extension MultipartDataEncoder {
    
    /// Encodes multipart data into the multipart/form-data format.
    ///
    /// - Parameters:
    ///   - container: the container with data parts
    ///   - boundary: the boundary used to separate parts
    /// - Returns: the encoded data
    /// - Throws: `MultipartError` in case of an encoding error
    private func encodeMultipartData(
        _ container: MultipartDataContainer,
        boundary: String
    ) throws(MultipartError) -> Data {
        var data = Data()
        
        // Encode each part
        for item in container.items {
            try data.append(itemEncoder.encode(item, boundary: boundary))
        }
        
        // Add the final boundary
        data.append("--\(boundary)--\(String.newLine)".safeTextData)
        
        return data
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
    fileprivate static let bufferSize = 1024
}
