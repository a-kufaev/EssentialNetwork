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

/// Manages an HTTP request whose response body is delivered incrementally — e.g. Server-Sent
/// Events or any long-lived streaming endpoint.
///
/// It mirrors `DataRequest`, but instead of buffering the whole body it forwards each chunk as
/// it arrives through an `AsyncThrowingStream`. The retry/interceptor machinery inherited from
/// `BaseRequest` still applies to the *initial* response, so an interceptor can refresh a token
/// on `401` and transparently restart the stream before any bytes reach the caller. A failure
/// that happens once the body is already streaming is not retried (a stream can't be replayed).
///
/// ## Usage example:
/// ```swift
/// let request = try await session.streamRequest(
///     URL(string: "https://api.example.com/chat")!,
///     method: .post,
///     headers: ["Accept": "text/event-stream"],
///     body: payload,
///     encoder: nil,
///     interceptor: authInterceptor
/// )
/// for try await chunk in request.stream() {
///     handle(chunk)
/// }
/// ```
public final class DataStreamRequest: BaseRequest, @unchecked Sendable {

    typealias RequestFactory = @Sendable () async throws(NetworkError) -> URLRequest

    private let requestFactory: RequestFactory
    private nonisolated(unsafe) var continuation: AsyncThrowingStream<Data, any Error>.Continuation?
    /// Set once a 2xx response header is seen; from then on body chunks are the real stream.
    private nonisolated(unsafe) var isStreaming = false
    /// Body accumulated before a 2xx is confirmed (i.e. an error body) — kept for the retry payload.
    private nonisolated(unsafe) var errorData = Data()

    init(
        session: URLSession,
        eventMonitor: NetworkEventMonitor,
        initialRequest: URLRequest,
        requestFactory: @escaping RequestFactory,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        self.requestFactory = requestFactory
        let task = session.dataTask(with: initialRequest)
        super.init(
            session: session,
            task: task,
            eventMonitor: eventMonitor,
            interceptors: interceptors,
            requestID: requestID
        )
        task.delegate = self
    }

    override func prepareForRetry() {
        super.prepareForRetry()
        isStreaming = false
        errorData.removeAll(keepingCapacity: false)
    }

    override func recreateTask() async throws(NetworkError) -> URLSessionTask {
        let request = try await requestFactory()
        let task = session.dataTask(with: request)
        task.delegate = self
        return task
    }

    /// Starts the request and returns its body as an async stream of chunks. Cancelling the
    /// stream (or the iterating task) cancels the underlying request.
    public func stream() -> AsyncThrowingStream<Data, any Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] termination in
                if case .cancelled = termination { self?.cancel() }
            }
            resume()
        }
    }
}

// MARK: - URLSessionDataDelegate

extension DataStreamRequest: URLSessionDataDelegate {

    /// Inspect the headers: a 2xx means the body that follows is the real stream; anything else
    /// is an error body we buffer so the retrier (e.g. token refresh on 401) can act on it.
    public func urlSession(
        _: URLSession,
        dataTask _: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if let http = response as? HTTPURLResponse, HTTPStatus(statusCode: http.statusCode).isSuccess {
            isStreaming = true
        }
        completionHandler(.allow)
    }

    public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        eventMonitor.request(dataTask.safeRequest, didReceiveData: data, requestID: requestID)
        if isStreaming {
            continuation?.yield(data)
        } else {
            errorData.append(data)
        }
    }
}

// MARK: - URLSessionTaskDelegate

extension DataStreamRequest: URLSessionTaskDelegate {

    public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        status = .finished
        eventMonitor.requestDidFinish(
            task.safeRequest,
            response: task.response,
            error: error,
            metrics: latestMetrics,
            requestID: requestID
        )
        latestMetrics = nil

        if let urlError = error as? URLError, urlError.code == .cancelled {
            eventMonitor.requestDidCancel(task.safeRequest, requestID: requestID)
            continuation?.finish(throwing: NetworkError.explicitlyCancelled)
            return
        }

        // The stream ran to completion successfully.
        if isStreaming, error == nil {
            continuation?.finish()
            return
        }

        // Transport error, or a non-2xx received before the body streamed: give the retrier a
        // chance (e.g. refresh the token on 401 and restart), otherwise finish with the error.
        let httpResponse = task.response as? HTTPURLResponse
        let netError = Self.error(from: error, response: httpResponse, body: errorData)
        Task {
            if await attemptRetry(response: httpResponse, payload: .data(errorData), error: netError) {
                return
            }
            eventMonitor.requestDidFail(task.safeRequest, error: netError, requestID: requestID)
            continuation?.finish(throwing: netError)
        }
    }

    public func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        latestMetrics = metrics
        eventMonitor.request(task.safeRequest, didCollect: metrics, requestID: requestID)
    }

    public func urlSession(_: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        eventMonitor.requestIsWaitingForConnectivity(task.safeRequest, requestID: requestID)
    }

    public func urlSession(
        _: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        eventMonitor.request(
            task.safeRequest,
            willPerformHTTPRedirection: response,
            newRequest: request,
            requestID: requestID
        )
        completionHandler(request)
    }

    public func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        eventMonitor.request(task.safeRequest, didReceive: challenge, requestID: requestID)
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Private

extension DataStreamRequest {

    private static func error(from error: (any Error)?, response: HTTPURLResponse?, body: Data) -> NetworkError {
        if let error {
            return .executionFailed(error)
        }
        if let response {
            return .unsuccessfulResponse(HTTPStatus(statusCode: response.statusCode), body)
        }
        return .invalidResponse(body, URLResponse())
    }

    @discardableResult
    private func attemptRetry(
        response: HTTPURLResponse?,
        payload: NetworkRequestRetryPayload,
        error: any Error
    ) async -> Bool {
        guard shouldRetry(response: response, payload: payload, error: error) else { return false }
        do {
            try await retry(response: response, payload: payload, error: error)
        } catch let retryError as NetworkError {
            continuation?.finish(throwing: retryError)
        } catch {
            continuation?.finish(throwing: NetworkError.executionFailed(error))
        }
        return true
    }
}
