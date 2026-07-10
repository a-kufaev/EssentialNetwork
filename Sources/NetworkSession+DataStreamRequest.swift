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

// swiftlint:disable function_parameter_count

import Foundation

// MARK: - DataStreamRequest Methods

extension NetworkSession {

    /// Creates a streaming request with query parameters and returns a `DataStreamRequest`.
    ///
    /// The response body is delivered incrementally via `DataStreamRequest.stream()`. Use this
    /// for Server-Sent Events or other long-lived streaming endpoints. Interceptors adapt the
    /// request and can refresh/retry the initial response exactly as for a normal request.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - parameters: query parameters for the URL
    ///   - interceptor: an interceptor for request adaptation and retries
    /// - Returns: a `DataStreamRequest`; call `stream()` to consume the body
    /// - Throws: `NetworkError` if building the request fails
    public func streamRequest(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataStreamRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, parameters: parameters)
        return try await buildStreamRequest(using: configuration, encoder: nil, interceptor: interceptor)
    }

    /// Creates a streaming request with a JSON body and returns a `DataStreamRequest`.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - body: the object to serialize as JSON in the request body
    ///   - encoder: the JSON encoder used to serialize the body
    ///   - interceptor: an interceptor for request adaptation and retries
    /// - Returns: a `DataStreamRequest`; call `stream()` to consume the body
    /// - Throws: `NetworkError` if building the request fails
    public func streamRequest(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: RequestBody?,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataStreamRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, body: body)
        return try await buildStreamRequest(using: configuration, encoder: encoder, interceptor: interceptor)
    }
}

// MARK: - Private Methods

extension NetworkSession {

    private func buildStreamRequest(
        using configuration: RequestConfiguration,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataStreamRequest {
        let requestID = UUID()
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestFactory = makeRequestFactory(
            configuration: configuration,
            encoder: encoder,
            interceptors: interceptorsChain,
            requestID: requestID
        )
        let request = try await requestFactory()
        return DataStreamRequest(
            session: session,
            eventMonitor: eventMonitor,
            initialRequest: request,
            requestFactory: requestFactory,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
}

// swiftlint:enable function_parameter_count
