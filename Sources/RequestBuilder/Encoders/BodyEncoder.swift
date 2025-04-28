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

/// The type for a request body: any object conforming to `Encodable`.
public typealias RequestBody = Encodable

/// Encodes the request body into a `URLRequest`.
///
/// `BodyEncoder` serializes the provided object into JSON:
/// 1. Sets the `Content-Type: application/json` header so the server understands the data format.
/// 2. Uses a `JSONEncoder` (the one passed to the method or its own) to convert the `Encodable` into `Data`.
/// 3. Assigns the resulting bytes to the request's `httpBody`.
struct BodyEncoder: AnyBodyEncoder {
    
    let jsonEncoder: JSONEncoder
    
    /// Embeds the request body into a `URLRequest`.
    ///
    /// - Parameters:
    ///   - urlRequest: the original request without an `httpBody`
    ///   - body: the `Encodable`-conforming object to serialize
    ///   - jsonEncoder: an optional `JSONEncoder` (for example, to configure the date or key format);
    ///                  if nil, the default encoder from `BodyEncoder` is used.
    /// - Returns: a `URLRequest` with a populated `httpBody` and a `Content-Type` header
    /// - Throws: `NetworkError.bodyEncodingFailed` if serialization fails
    func encode(
        _ urlRequest: URLRequest,
        with body: RequestBody,
        jsonEncoder: JSONEncoder?
    ) throws(NetworkError) -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.setHeader(.contentType(MIMEType.json.rawValue))
        let jsonEncoder = jsonEncoder ?? self.jsonEncoder
        do {
            let data = try jsonEncoder.encode(body)
            urlRequest.httpBody = data
            return urlRequest
        } catch {
            throw .bodyEncodingFailed(error)
        }
    }
}
