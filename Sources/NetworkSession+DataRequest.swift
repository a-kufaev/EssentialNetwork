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

// MARK: - DataRequest Methods

extension NetworkSession {
    
    /// Creates a request with query parameters and returns a `DataRequest` for control.
    ///
    /// Initiates an HTTP request with query parameters. Returns a `DataRequest` that lets you
    /// control the request lifecycle (suspend, resume, cancel).
    /// Use this for requests that require control over the execution process.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - parameters: query parameters for the URL
    ///   - interceptor: an interceptor for additional request adaptation and retries
    /// - Returns: a `DataRequest` for managing the request
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// let dataRequest = try await session.request(
    ///     URL(string: "https://api.example.com/users")!,
    ///     method: .get,
    ///     headers: ["Authorization": "Bearer token"],
    ///     parameters: ["page": "1"],
    ///     interceptor: nil
    /// )
    ///
    /// dataRequest
    ///     .responseData { result in
    ///         switch result {
    ///         case let .success(response):
    ///             print("Response: \(response)")
    ///         case let .failure(error):
    ///             print("Error: \(error)")
    ///         }
    ///     }
    ///     .resume()
    /// ```
    public func request(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, parameters: parameters)
        let requestID = UUID()
        return try await buildDataRequest(
            using: configuration,
            encoder: nil,
            interceptor: interceptor,
            requestID: requestID
        )
    }
    
    /// Creates a request with a JSON body and returns a `DataRequest` for control.
    ///
    /// Initiates an HTTP request with JSON data in the body. Returns a `DataRequest` that lets you
    /// control the request lifecycle (suspend, resume, cancel).
    /// Use this for requests with JSON data that require control over the process.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - body: the object to serialize as JSON in the request body
    ///   - encoder: the JSON encoder used to serialize the body
    ///   - interceptor: an interceptor for additional request adaptation and retries
    /// - Returns: a `DataRequest` for managing the request
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// struct CreateUser: Encodable {
    ///     let name: String
    ///     let email: String
    /// }
    ///
    /// let user = CreateUser(name: "John", email: "john@example.com")
    /// let dataRequest = try await session.request(
    ///     URL(string: "https://api.example.com/users")!,
    ///     method: .post,
    ///     headers: nil,
    ///     body: user,
    ///     encoder: nil,
    ///     interceptor: nil
    /// )
    ///
    /// dataRequest
    ///     .responseDecodable(of: User.self) { result in
    ///         // Handle the decoded model
    ///     }
    ///     .resume()
    /// ```
    public func request(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: RequestBody?,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, body: body)
        let requestID = UUID()
        return try await buildDataRequest(
            using: configuration,
            encoder: encoder,
            interceptor: interceptor,
            requestID: requestID
        )
    }
}

// MARK: - Private Methods

extension NetworkSession {
    
    /// Builds a `DataRequest` using the given configuration.
    private func buildDataRequest(
        using configuration: RequestConfiguration,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?,
        requestID: UUID
    ) async throws(NetworkError) -> DataRequest {
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestFactory = makeRequestFactory(
            configuration: configuration,
            encoder: encoder,
            interceptors: interceptorsChain,
            requestID: requestID
        )
        let request = try await requestFactory()
        return DataRequest(
            session: session,
            eventMonitor: eventMonitor,
            dataDecoder: dataDecoder,
            initialRequest: request,
            requestFactory: requestFactory,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
}

// swiftlint:enable function_parameter_count
