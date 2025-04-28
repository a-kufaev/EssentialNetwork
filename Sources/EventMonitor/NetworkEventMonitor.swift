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

/// A protocol for monitoring network request events.
///
/// Used for logging, analytics, and debugging of network interactions.
/// @mockable
public protocol NetworkEventMonitor: Sendable {
    
    /// Called right after the initial `URLRequest` is built, before interceptors are applied.
    func requestDidCreateInitialRequest(_ request: URLRequest, requestID: UUID)
    
    /// Called after the chain of interceptors has been applied.
    func requestDidAdaptRequest(_ initialRequest: URLRequest, to adaptedRequest: URLRequest, requestID: UUID)
    
    /// Called when the request could not be built.
    func requestDidFailToCreateRequest(_ error: Error, requestID: UUID)
    
    /// Called before starting/resuming the request (when the task is about to `resume()`).
    func requestWillStart(_ request: URLRequest, requestID: UUID)
    
    /// Called right after `resume()`.
    func requestDidResume(_ request: URLRequest, requestID: UUID)
    
    /// Called after `suspend()`.
    func requestDidSuspend(_ request: URLRequest, requestID: UUID)
    
    /// Called after an HTTP response is received successfully.
    func requestDidReceive(_ request: URLRequest, response: HTTPURLResponse, data: Data, requestID: UUID) async
    
    /// Called when a valid application response is obtained (after validation/parsing).
    func requestDidParseResponse(_ request: URLRequest, response: HTTPURLResponse, data: Data, requestID: UUID)
    
    /// Called when the request fails.
    func requestDidFail(_ request: URLRequest, error: Error, requestID: UUID)
    
    /// Called before a new request attempt begins.
    func requestRetryWillStart(
        _ request: URLRequest,
        attempt: UInt,
        dueTo error: Error,
        delay: TimeInterval?,
        requestID: UUID
    )
    
    /// Called when the request is cancelled manually or by the system.
    func requestDidCancel(_ request: URLRequest, requestID: UUID)
    
    /// Called when the task finishes (success/error/cancellation).
    func requestDidFinish(
        _ request: URLRequest,
        response: URLResponse?,
        error: Error?,
        metrics: URLSessionTaskMetrics?,
        requestID: UUID
    )
    
    /// Called when the system is waiting for connectivity before performing the request.
    func requestIsWaitingForConnectivity(_ request: URLRequest, requestID: UUID)
    
    /// Reports a redirect.
    func request(
        _ request: URLRequest,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest: URLRequest,
        requestID: UUID
    )
    
    /// Reports a challenge (TLS, authentication).
    func request(
        _ request: URLRequest,
        didReceive challenge: URLAuthenticationChallenge,
        requestID: UUID
    )
    
    /// Reports collected `URLSessionTask` metrics.
    func request(_ request: URLRequest, didCollect metrics: URLSessionTaskMetrics, requestID: UUID)
    
    /// Reports progress while sending data.
    func request(
        _ request: URLRequest,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64,
        requestID: UUID
    )
    
    /// Reports the receipt of a chunk of data (DataTask/UploadTask).
    func request(_ request: URLRequest, didReceiveData data: Data, requestID: UUID)
    
    /// Reports download progress (DownloadTask).
    func request(
        _ request: URLRequest,
        didReceiveBytes bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
        requestID: UUID
    )
}

// MARK: - Default Implementation

extension NetworkEventMonitor {
    
    /// Default implementation - does nothing.
    public func requestDidCreateInitialRequest(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidAdaptRequest(_: URLRequest, to _: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidFailToCreateRequest(_: Error, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestWillStart(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidResume(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidSuspend(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidReceive(_: URLRequest, response _: HTTPURLResponse, data _: Data, requestID _: UUID) async {}
    
    /// Default implementation - does nothing.
    public func requestDidParseResponse(_: URLRequest, response _: HTTPURLResponse, data _: Data, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidFail(_: URLRequest, error _: Error, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestRetryWillStart(
        _: URLRequest,
        attempt _: UInt,
        dueTo _: Error,
        delay _: TimeInterval?,
        requestID _: UUID
    ) {}
    
    /// Default implementation - does nothing.
    public func requestDidCancel(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func requestDidFinish(
        _: URLRequest,
        response _: URLResponse?,
        error _: Error?,
        metrics _: URLSessionTaskMetrics?,
        requestID _: UUID
    ) {}
    
    /// Default implementation - does nothing.
    public func requestIsWaitingForConnectivity(_: URLRequest, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func request(
        _: URLRequest,
        willPerformHTTPRedirection _: HTTPURLResponse,
        newRequest _: URLRequest,
        requestID _: UUID
    ) {}
    
    /// Default implementation - does nothing.
    public func request(
        _: URLRequest,
        didReceive _: URLAuthenticationChallenge,
        requestID _: UUID
    ) {}
    
    /// Default implementation - does nothing.
    public func request(_: URLRequest, didCollect _: URLSessionTaskMetrics, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func request(
        _: URLRequest,
        didSendBodyData _: Int64,
        totalBytesSent _: Int64,
        totalBytesExpectedToSend _: Int64,
        requestID _: UUID
    ) {}
    
    /// Default implementation - does nothing.
    public func request(_: URLRequest, didReceiveData _: Data, requestID _: UUID) {}
    
    /// Default implementation - does nothing.
    public func request(
        _: URLRequest,
        didReceiveBytes _: Int64,
        totalBytesWritten _: Int64,
        totalBytesExpectedToWrite _: Int64,
        requestID _: UUID
    ) {}
    
}
