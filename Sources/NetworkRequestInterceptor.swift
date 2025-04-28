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

// MARK: - Adapter

/// A protocol for adapting network requests.
///
/// Lets you modify a built `URLRequest` before it is sent:
/// for example, to add authorization headers, tokens, cache strategies, or other parameters.
///
/// The adapter is invoked in the request-sending chain before execution.
public protocol NetworkRequestAdapter: Sendable {
    
    func adapt(_ urlRequest: URLRequest) async throws -> URLRequest
}

// MARK: - Retrier

public protocol NetworkRequestRetrier: Sendable {
    
    func shouldRetry(context: NetworkRequestRetryContext, dueTo error: any Error) -> Bool
    func retry(
        _ context: NetworkRequestRetryContext,
        dueTo error: any Error
    ) async -> NetworkRequestRetryResult
}

// MARK: - Interceptor

/// @mockable
public protocol NetworkRequestInterceptor: NetworkRequestAdapter, NetworkRequestRetrier {}

extension NetworkRequestInterceptor {
    
    public func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        urlRequest
    }
    
    public func shouldRetry(context _: NetworkRequestRetryContext, dueTo _: any Error) -> Bool {
        false
    }
    
    public func retry(
        _: NetworkRequestRetryContext,
        dueTo _: any Error
    ) async -> NetworkRequestRetryResult {
        .retry
    }
}
