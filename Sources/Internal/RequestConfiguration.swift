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

/// Stores all parameters required to build a `URLRequest`.
///
/// Provides two initializers for a clear separation:
/// - requests without a body — using query parameters;
/// - requests with a body — using an `Encodable` object.
struct RequestConfiguration: @unchecked Sendable {
    
    /// The target URL of the request.
    let url: URL
    
    /// The HTTP method (GET, POST, etc.).
    let method: HTTPMethod
    
    /// Arbitrary HTTP headers.
    let headers: HTTPHeaders?
    
    /// The dictionary of query parameters (used when the request has no body).
    let queryParameters: QueryParameters?
    
    /// The request body as an `Encodable` (used when there are no query parameters).
    let body: Encodable?
    
    /// Creates a configuration for requests without a body, using query parameters.
    init(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        queryParameters = parameters
        body = nil
    }
    
    /// Creates a configuration for requests with a body (for example, POST/PUT).
    init(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: Encodable?
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        queryParameters = nil
        self.body = body
    }
}
