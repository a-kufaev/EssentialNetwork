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

/// `NetworkSession` is a ready-to-use network session implementation
/// that simplifies performing HTTP requests in a Swift async style.
public final class NetworkSession {
    
    let session: URLSession

    let requestBuilder: AnyRequestBuilder
    let dataDecoder: AnyDataDecoder
    let multipartDataEncoder: AnyMultipartDataEncoder

    private let defaultInterceptors: [NetworkRequestInterceptor]
    let eventMonitor: CompositeEventMonitor
    
    init(
        session: URLSession,
        requestBuilder: AnyRequestBuilder,
        dataDecoder: AnyDataDecoder,
        multipartDataEncoder: AnyMultipartDataEncoder,
        interceptors: [NetworkRequestInterceptor] = [],
        eventMonitors: [NetworkEventMonitor] = []
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.dataDecoder = dataDecoder
        self.multipartDataEncoder = multipartDataEncoder
        defaultInterceptors = interceptors
        eventMonitor = CompositeEventMonitor(monitors: eventMonitors)
    }

    public convenience init(
        session: URLSession = URLSession(configuration: .default),
        interceptors: [NetworkRequestInterceptor] = [],
        eventMonitors: [NetworkEventMonitor] = [],
        decoder: JSONDecoder = JSONDecoder()
    ) {
        let queryEncoder = QueryParametersEncoder()
        let bodyEncoder = BodyEncoder(jsonEncoder: JSONEncoder())
        let requestBuilder = RequestBuilder(
            queryEncoder: queryEncoder,
            bodyEncoder: bodyEncoder
        )
        let dataDecoder = DataDecoder(jsonDecoder: decoder)
        let multipartDataEncoder = MultipartDataEncoder()
        self.init(
            session: session,
            requestBuilder: requestBuilder,
            dataDecoder: dataDecoder,
            multipartDataEncoder: multipartDataEncoder,
            interceptors: interceptors,
            eventMonitors: eventMonitors
        )
    }
    
}

// MARK: - AnyNetworkSession

extension NetworkSession: AnyNetworkSession {
    
    /// Cancels all active `URLSession` network tasks.
    public func cancelAllRequests() async {
        let tasks = await session.allTasks
        tasks.forEach { $0.cancel() }
    }
    
    public func cleanupCookies() {
        guard let cookieStorage = session.configuration.httpCookieStorage else { return }
        cookieStorage.cookies?.forEach { cookie in
            cookieStorage.deleteCookie(cookie)
        }
    }
}

// MARK: - Internal Methods

extension NetworkSession {
    
    /// Adapts the request through the chain of interceptors.
    func adaptRequest(
        _ request: URLRequest,
        using interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) async throws(NetworkError) -> URLRequest {
        var request = request
        do {
            for adapter in interceptors {
                let adapted = try await adapter.adapt(request)
                eventMonitor.requestDidAdaptRequest(request, to: adapted, requestID: requestID)
                request = adapted
            }
            return request
        } catch {
            throw .requestAdaptationFailed(error)
        }
    }
    
    typealias URLRequestFactory = @Sendable () async throws(NetworkError) -> URLRequest
    
    /// Creates a factory that can rebuild the `URLRequest` at any time,
    /// taking all interceptors into account.
    func makeRequestFactory(
        configuration: RequestConfiguration,
        encoder: JSONEncoder?,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) -> URLRequestFactory {
        let builder = requestBuilder
        return { [weak self] () async throws(NetworkError) -> URLRequest in
            guard let self else { throw NetworkError.explicitlyCancelled }
            do {
                var request = try builder.build(using: configuration, encoder: encoder)
                self.eventMonitor.requestDidCreateInitialRequest(request, requestID: requestID)
                request = try await self.adaptRequest(request, using: interceptors, requestID: requestID)
                return request
            } catch {
                self.eventMonitor.requestDidFailToCreateRequest(error, requestID: requestID)
                if let networkError = error as? NetworkError {
                    throw networkError
                }
                throw NetworkError.executionFailed(error)
            }
        }
    }
    
    /// Returns the combined list of interceptors: global + local.
    func combinedInterceptors(with interceptor: NetworkRequestInterceptor?) -> [NetworkRequestInterceptor] {
        defaultInterceptors + (interceptor.map { [$0] } ?? [])
    }
}
