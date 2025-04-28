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

/// A collection of HTTP headers.
public struct HTTPHeaders: Equatable, Sendable {
    
    /// The internal header storage.
    private var headers: [String: String] = [:]
    
    /// Creates an empty header collection.
    public init() {}

    /// Creates a collection from an array of HTTP headers.
    ///
    /// Duplicate header names (case-insensitive) are replaced by the last
    /// encountered value.
    ///
    /// - Parameter headers: an array of HTTP headers
    public init(_ headers: [HTTPHeader]) {
        headers.forEach { self.headers[$0.name] = $0.value }
    }

    /// Creates a collection from a dictionary.
    ///
    /// Duplicate header names (case-insensitive) are replaced by the last
    /// encountered value.
    ///
    /// - Parameter dictionary: a dictionary of headers
    public init(_ dictionary: [String: String]) {
        headers = dictionary
    }
    
    /// Adds or updates a header by name and value.
    ///
    /// - Parameters:
    ///   - name: the header name
    ///   - value: the header value
    public mutating func set(name: String, value: String) {
        headers[name] = value
    }

    /// Adds or updates a header.
    ///
    /// - Parameter header: the HTTP header to add
    public mutating func set(_ header: HTTPHeader) {
        headers[header.name] = header.value
    }
    
    /// Looks up a header value by name.
    ///
    /// - Parameter name: the header name to look up
    /// - Returns: the header value, if it exists
    public func value(for name: String) -> String? {
        headers[name]
    }

    /// Accesses a header by name through a subscript.
    ///
    /// - Parameter name: the header name
    public subscript(_ name: String) -> String? {
        get { headers[name] }
        set { headers[name] = newValue }
    }
    
    /// A dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the headers.
    public var dictionary: [String: String] {
        headers
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension HTTPHeaders: ExpressibleByDictionaryLiteral {

    /// Creates a collection from a dictionary literal.
    ///
    /// - Parameter elements: key-value pairs for the headers
    public init(dictionaryLiteral elements: (String, String)...) {
        elements.forEach { headers[$0] = $1 }
    }
}

// MARK: - ExpressibleByArrayLiteral

extension HTTPHeaders: ExpressibleByArrayLiteral {

    /// Creates a collection from an array literal.
    ///
    /// - Parameter elements: the HTTP headers
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(elements)
    }
}

// MARK: - HTTPHeader

/// A representation of a single HTTP header as a name-value pair.
public struct HTTPHeader: Equatable, Sendable {
    
    /// The header name.
    public let name: String

    /// The header value.
    public let value: String

    /// Creates a header with the given name and value.
    ///
    /// - Parameters:
    ///   - name: the header name
    ///   - value: the header value
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - URLRequest Extension

extension URLRequest {
    
    /// Returns `allHTTPHeaderFields` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        get { allHTTPHeaderFields.map(HTTPHeaders.init) ?? HTTPHeaders() }
        set { allHTTPHeaderFields = newValue.dictionary }
    }
    
    /// Sets an HTTP header on the request.
    ///
    /// - Parameter header: the HTTP header to set
    public mutating func setHeader(_ header: HTTPHeader) {
        headers.set(header)
    }
}

// MARK: - HTTPURLResponse Extension

extension HTTPURLResponse {

    /// Returns `allHeaderFields` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        (allHeaderFields as? [String: String]).map(HTTPHeaders.init) ?? HTTPHeaders()
    }
}
