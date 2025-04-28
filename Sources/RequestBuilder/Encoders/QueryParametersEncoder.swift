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

/// Query request parameters represented as a dictionary.
public typealias QueryParameters = [String: QueryValue]

/// Encodes query parameters for a `URLRequest`.
///
/// Builds the parameter string in the `application/x-www-form-urlencoded` format,
/// where:
/// - each "key=value" pair is separated by an ampersand (&);
/// - keys and values are converted to strings and escaped per RFC 3986;
/// - scalar types, arrays, and nested dictionaries are supported.
///
/// This format is used in HTML forms and APIs expecting data in `x-www-form-urlencoded`.
///
/// Example:
/// ```swift
/// let params: QueryParameters = [
///   "name": "John",
///   "age": 30,
///   "tags": ["swift", "network"]
/// ]
/// let request = try encoder.encode(urlRequest, with: params)
/// // The URL will contain ?age=30&name=John&tags=swift&tags=network
/// ```
struct QueryParametersEncoder: AnyQueryParametersEncoder {
    
    /// Embeds the provided parameters into a `URLRequest`.
    ///
    /// - Parameters:
    ///   - urlRequest: the original request without query parameters
    ///   - parameters: the dictionary of query parameters
    /// - Returns: a new `URLRequest` with `url` + `queryItems` and a `Content-Type` header
    /// - Throws: `NetworkError.invalidURL` if the request has no base URL
    func encode(_ urlRequest: URLRequest, with parameters: QueryParameters) throws(NetworkError) -> URLRequest {
        guard let url = urlRequest.url else {
            throw .invalidURL
        }
        
        guard var urlComponents = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ), !parameters.isEmpty else { return urlRequest }
        
        var urlRequest = urlRequest
        
        // For query requests, set the appropriate Content-Type
        urlRequest.setHeader(.contentType("application/x-www-form-urlencoded; charset=utf-8"))
        
        // Build URLQueryItem values from the parameters
        urlComponents.percentEncodedQueryItems = makeQueryItems(parameters)
        urlRequest.url = urlComponents.url
        
        return urlRequest
    }
    
    /// Converts the dictionary into an array of (key, value) pairs, accounting for nested structures.
    private func makeQueryItems(_ parameters: QueryParameters) -> [URLQueryItem] {
        parameters
            .sorted(by: { $0.key < $1.key })
            .flatMap { key, value in queryComponents(fromKey: key, value: value) }
            .map(URLQueryItem.init)
    }
    
    /// Recursively processes a `QueryValue`:
    /// — dictionaries become key[nestedKey]=…,
    /// — arrays duplicate the key,
    /// — scalars are escaped.
    private func queryComponents(fromKey key: String, value: QueryValue) -> [(String, String)] {
        var components: [(String, String)] = []
        switch value {
        case let .dictionary(dictionary):
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        case let .array(array):
            for value in array {
                components += queryComponents(fromKey: key, value: value)
            }
        case let .int(intValue):
            components.append((key.percentEncoded, "\(intValue)".percentEncoded))
        case let .double(doubleValue):
            components.append((key.percentEncoded, "\(doubleValue)".percentEncoded))
        case let .bool(boolValue):
            components.append((key.percentEncoded, (boolValue ? "true" : "false").percentEncoded))
        case let .string(stringValue):
            components.append((key.percentEncoded, stringValue.percentEncoded))
        }
        return components
    }
}
