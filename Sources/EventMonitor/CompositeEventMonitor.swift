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

/// A composite event monitor that delegates events to multiple monitors.
///
/// Allows several event monitors to be used at once,
/// dispatching each event to every registered monitor.
struct CompositeEventMonitor {
    
    let monitors: [NetworkEventMonitor]
    
    /// Performs a synchronous event for all monitors.
    private func performEvent(_ event: @escaping @Sendable (any NetworkEventMonitor) -> Void) {
        for monitor in monitors {
            event(monitor)
        }
    }
    
    /// Performs an asynchronous event for all monitors.
    private func performEvent(_ event: @escaping @Sendable (any NetworkEventMonitor) async -> Void) async {
        for monitor in monitors {
            await event(monitor)
        }
    }
    
}

// MARK: - NetworkEventMonitor

extension CompositeEventMonitor: NetworkEventMonitor {
    
    func requestDidCreateInitialRequest(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestDidCreateInitialRequest(request, requestID: requestID) }
    }
    
    func requestDidAdaptRequest(_ initialRequest: URLRequest, to adaptedRequest: URLRequest, requestID: UUID) {
        performEvent { $0.requestDidAdaptRequest(initialRequest, to: adaptedRequest, requestID: requestID) }
    }
    
    func requestDidFailToCreateRequest(_ error: any Error, requestID: UUID) {
        performEvent { $0.requestDidFailToCreateRequest(error, requestID: requestID) }
    }
    
    func requestWillStart(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestWillStart(request, requestID: requestID) }
    }
    
    func requestDidResume(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestDidResume(request, requestID: requestID) }
    }
    
    func requestDidSuspend(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestDidSuspend(request, requestID: requestID) }
    }

    func requestDidReceive(_ request: URLRequest, response: HTTPURLResponse, data: Data, requestID: UUID) async {
        await performEvent {
            await $0.requestDidReceive(request, response: response, data: data, requestID: requestID)
        }
    }
    
    func requestDidParseResponse(_ request: URLRequest, response: HTTPURLResponse, data: Data, requestID: UUID) {
        performEvent { $0.requestDidParseResponse(request, response: response, data: data, requestID: requestID) }
    }

    func requestDidFail(_ request: URLRequest, error: any Error, requestID: UUID) {
        performEvent { $0.requestDidFail(request, error: error, requestID: requestID) }
    }
    
    func requestRetryWillStart(
        _ request: URLRequest,
        attempt: UInt,
        dueTo error: any Error,
        delay: TimeInterval?,
        requestID: UUID
    ) {
        performEvent {
            $0.requestRetryWillStart(
                request,
                attempt: attempt,
                dueTo: error,
                delay: delay,
                requestID: requestID
            )
        }
    }
    
    func requestDidCancel(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestDidCancel(request, requestID: requestID) }
    }
    
    func requestDidFinish(
        _ request: URLRequest,
        response: URLResponse?,
        error: (any Error)?,
        metrics: URLSessionTaskMetrics?,
        requestID: UUID
    ) {
        performEvent {
            $0.requestDidFinish(request, response: response, error: error, metrics: metrics, requestID: requestID)
        }
    }
    
    func requestIsWaitingForConnectivity(_ request: URLRequest, requestID: UUID) {
        performEvent { $0.requestIsWaitingForConnectivity(request, requestID: requestID) }
    }
    
    func request(
        _ request: URLRequest,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest: URLRequest,
        requestID: UUID
    ) {
        performEvent {
            $0.request(
                request,
                willPerformHTTPRedirection: response,
                newRequest: newRequest,
                requestID: requestID
            )
        }
    }
    
    func request(
        _ request: URLRequest,
        didReceive challenge: URLAuthenticationChallenge,
        requestID: UUID
    ) {
        performEvent {
            $0.request(
                request,
                didReceive: challenge,
                requestID: requestID
            )
        }
    }
    
    func request(_ request: URLRequest, didCollect metrics: URLSessionTaskMetrics, requestID: UUID) {
        performEvent { $0.request(request, didCollect: metrics, requestID: requestID) }
    }
    
    func request(
        _ request: URLRequest,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64,
        requestID: UUID
    ) {
        performEvent {
            $0.request(
                request,
                didSendBodyData: bytesSent,
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend,
                requestID: requestID
            )
        }
    }
    
    func request(_ request: URLRequest, didReceiveData data: Data, requestID: UUID) {
        performEvent { $0.request(request, didReceiveData: data, requestID: requestID) }
    }
    
    func request(
        _ request: URLRequest,
        didReceiveBytes bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
        requestID: UUID
    ) {
        performEvent {
            $0.request(
                request,
                didReceiveBytes: bytesWritten,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite,
                requestID: requestID
            )
        }
    }
}
