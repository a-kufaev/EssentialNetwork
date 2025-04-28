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

/// The base status for all request types.
///
/// Tracks the current state of the request execution process and allows
/// controlling the execution of the task.
public enum RequestStatus: Sendable {

    /// The request has not started (the initial state).
    case idle
    /// The request is active and executing.
    case resumed
    /// The request has been suspended by the user.
    case suspended
    /// The request has been cancelled by the user.
    case cancelled
    /// The request has finished (successfully or with an error).
    case finished
}

/// The base class for all types of network requests.
///
/// Contains the shared logic for managing state, progress,
/// retries, and monitoring notifications.
open class BaseRequest: NSObject, @unchecked Sendable {
    
    /// The unique request identifier for tracking in event monitors.
    public let requestID: UUID
    
    let session: URLSession
    
    private(set) var task: URLSessionTask
    
    /// The event monitor for logging and tracking requests.
    let eventMonitor: NetworkEventMonitor
    
    /// The chain of interceptors (global and local) applied to the request.
    let interceptors: [NetworkRequestInterceptor]
    
    /// The request progress object.
    ///
    /// Contains information about the current execution progress:
    /// - `totalUnitCount`: the total amount of work
    /// - `completedUnitCount`: the completed amount of work
    /// - `fractionCompleted`: the completion fraction (0.0 - 1.0)
    public let progress = Progress()
    
    /// The current request status.
    ///
    /// Changes automatically during the request execution.
    public nonisolated(unsafe) var status: RequestStatus = .idle
    
    /// The number of retries performed.
    ///
    /// Incremented when a retry is scheduled.
    public private(set) nonisolated(unsafe) var retryAttempts: UInt = 0
    
    /// The latest collected URLSessionTask metrics (updated on delegate events).
    nonisolated(unsafe) var latestMetrics: URLSessionTaskMetrics?
    
    /// The current URLSession request.
    public var currentRequest: URLRequest {
        task.safeRequest
    }
    
    /// Checks whether the request is active.
    public var isResumed: Bool {
        status == .resumed
    }
    
    /// Checks whether the request has been cancelled.
    public var isCancelled: Bool {
        status == .cancelled
    }
    
    /// Checks whether the request is suspended.
    public var isSuspended: Bool {
        status == .suspended
    }
    
    /// Checks whether the request has finished.
    public var isFinished: Bool {
        status == .finished
    }
    
    init(
        session: URLSession,
        task: URLSessionTask,
        eventMonitor: NetworkEventMonitor,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        self.session = session
        self.task = task
        self.eventMonitor = eventMonitor
        self.interceptors = interceptors
        self.requestID = requestID
        super.init()
    }
    
    /// Starts or resumes the request.
    ///
    /// The request can only be started from the `.idle` or `.suspended` states.
    /// Returns `self` to support call chaining.
    ///
    /// - Returns: `self` for call chaining
    @discardableResult
    open func resume() -> Self {
        guard [.idle, .suspended].contains(status) else { return self }
        let safeRequest = task.safeRequest
        eventMonitor.requestWillStart(safeRequest, requestID: requestID)
        performResume()
        status = .resumed
        eventMonitor.requestDidResume(safeRequest, requestID: requestID)
        return self
    }
    
    /// Suspends the request.
    ///
    /// The request can only be suspended from the `.resumed` state.
    /// Returns `self` to support call chaining.
    ///
    /// - Returns: `self` for call chaining
    @discardableResult
    open func suspend() -> Self {
        guard [.resumed].contains(status) else { return self }
        performSuspend()
        status = .suspended
        eventMonitor.requestDidSuspend(task.safeRequest, requestID: requestID)
        return self
    }
    
    /// Cancels the request.
    ///
    /// The request can only be cancelled from the `.resumed` or `.suspended` states.
    /// After cancellation, the request cannot be resumed.
    open func cancel() {
        guard [.resumed, .suspended].contains(status) else { return }
        performCancel()
        status = .cancelled
    }
    
    // MARK: - State Management
    
    /// Overridden in subclasses to perform the specific resume logic.
    func performResume() {
        task.resume()
    }
    
    /// Overridden in subclasses to perform the specific suspend logic.
    func performSuspend() {
        task.suspend()
    }
    
    /// Overridden in subclasses to perform the specific cancel logic.
    func performCancel() {
        task.cancel()
    }
    
    /// Recreates the request task.
    ///
    /// Used when the request is retried.
    func recreateTask() async throws(NetworkError) -> URLSessionTask {
        // To be overridden in subclasses
        fatalError("Must be overridden!")
    }
    
    /// Preparatory procedure before retrying the request.
    func prepareForRetry() {
        progress.completedUnitCount = .zero
        progress.totalUnitCount = .zero
        latestMetrics = nil
        
        // Overridden in subclasses when necessary.
    }
    
}

// MARK: - Retries

extension BaseRequest {
    
    /// Checks whether a retry is needed for the current response/error.
    func shouldRetry(
        response: HTTPURLResponse?,
        payload: NetworkRequestRetryPayload,
        error: any Error
    ) -> Bool {
        selectRetrier(response: response, payload: payload, error: error) != nil
    }
    
    /// Initiates a request retry if a suitable retrier is found.
    func retry(
        response: HTTPURLResponse?,
        payload: NetworkRequestRetryPayload,
        error: any Error
    ) async throws {
        // A suitable retrier is selected from the chain
        guard let interceptor = selectRetrier(response: response, payload: payload, error: error) else {
            return
        }
        
        // Build the data for the retry
        let nextAttempt = retryAttempts + 1
        let context = NetworkRequestRetryContext(
            request: self,
            response: response,
            nextAttempt: nextAttempt,
            payload: payload
        )
        
        // Determine whether a retry is needed
        let result = await interceptor.retry(context, dueTo: error)
        switch result {
        case .retry:
            notifyRetryWillStart(attempt: nextAttempt, dueTo: error, delay: nil)
            // Retry the request immediately
            try await performRetryTransition(assigningAttempt: nextAttempt)
            
        case let .retryWithDelay(timeInterval):
            notifyRetryWillStart(attempt: nextAttempt, dueTo: error, delay: timeInterval)
            // Retry the request after a delay
            try? await Task.sleep(for: .seconds(timeInterval))
            try await performRetryTransition(assigningAttempt: nextAttempt)
            
        case let .doNotRetryWithError(error):
            // Do not retry the request and throw the error
            throw error
        }
    }
    
    /// Performs the request retry, reconfiguring the entire request state.
    private func performRetryTransition(assigningAttempt attempt: UInt) async throws(NetworkError) {
        retryAttempts = attempt
        prepareForRetry()
        let task = try await recreateTask()
        self.task = task
        status = .idle
        _ = resume()
    }
    
    /// Searches for a request retrier along the chain of interceptors.
    private func selectRetrier(
        response: HTTPURLResponse?,
        payload: NetworkRequestRetryPayload,
        error: any Error
    ) -> NetworkRequestInterceptor? {
        guard !interceptors.isEmpty else { return nil }
        let nextAttempt = retryAttempts + 1
        let context = NetworkRequestRetryContext(
            request: self,
            response: response,
            nextAttempt: nextAttempt,
            payload: payload
        )
        return interceptors.first { $0.shouldRetry(context: context, dueTo: error) }
    }
}

// MARK: - Retry Notifications

extension BaseRequest {
    
    private func notifyRetryWillStart(attempt: UInt, dueTo error: any Error, delay: TimeInterval?) {
        eventMonitor.requestRetryWillStart(
            task.safeRequest,
            attempt: attempt,
            dueTo: error,
            delay: delay,
            requestID: requestID
        )
    }
}

// MARK: - Async helpers

extension BaseRequest {
    
    /// A unified helper for async responses that accounts for `Task` cancellation.
    ///
    /// - The `body` parameter receives a closure that must be called when the request finishes.
    /// - The method automatically calls `resume()` and binds `cancel()` to the cancellation of the enclosing `Task`.
    /// - This guarantees that on `Task.cancel()` the network request finishes with `URLError.cancelled`,
    ///   and the caller receives `NetworkError.explicitlyCancelled`.
    func awaitResponse<T: Sendable>(
        _ body: (@escaping (Result<T, NetworkError>) -> Void) -> Void
    ) async throws(NetworkError) -> T {
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    body { result in
                        continuation.resume(with: result)
                    }
                    resume()
                }
            } onCancel: {
                cancel()
            }
        } catch let error as NetworkError {
            throw error
        } catch is CancellationError {
            throw NetworkError.explicitlyCancelled
        } catch {
            assertionFailure("This should never happen")
            throw NetworkError.executionFailed(error)
        }
    }
}

extension URLSessionTask {
    
    /// Safely retrieves the current request from the task or returns a stub.
    ///
    /// Works around the issue of creating a dummy URLRequest.
    var safeRequest: URLRequest {
        if let currentRequest {
            return currentRequest
        }
        
        // Create a minimal valid request as a fallback
        if let originalRequest {
            return originalRequest
        }
        
        // Last resort - create a basic request
        return URLRequest(url: URL.temporaryDirectory)
    }
}
