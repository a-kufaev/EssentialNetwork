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

/// Builds a `URLRequest` from a request configuration.
///
/// Used inside `NetworkSession` to prepare a request for sending.
struct RequestBuilder: AnyRequestBuilder {
    
    let queryEncoder: AnyQueryParametersEncoder
    let bodyEncoder: AnyBodyEncoder
    
    func build(using configuration: RequestConfiguration, encoder: JSONEncoder?) throws(NetworkError) -> URLRequest {
        var request = URLRequest(url: configuration.url)
        
        request.allHTTPHeaderFields = configuration.headers?.dictionary
        request.httpMethod = configuration.method.rawValue
        
        if let queryParameters = configuration.queryParameters {
            request = try queryEncoder.encode(request, with: queryParameters)
        }
        
        if let body = configuration.body {
            request = try bodyEncoder.encode(request, with: body, jsonEncoder: encoder)
        }
        
        return request
    }
}
