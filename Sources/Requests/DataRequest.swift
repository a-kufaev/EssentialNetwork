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

// swiftlint:disable file_length

import Foundation

/// The result of executing an HTTP request.
///
/// Contains either a successful response with data from the server,
/// or an error that occurred while executing the request.
public typealias DataRequestResult = Result<DataResponse, NetworkError>

/// Manages the process of executing an HTTP request.
///
/// `DataRequest` provides full control over the request execution process:
/// - Starting, suspending, resuming, and cancelling the request
/// - Handling results (success/error)
/// - A DSL interface for serializing responses
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
/// // Using the callback style
/// dataRequest
///     .responseData { result in
///         switch result {
///         case let .success(response):
///             handleSuccess(response)
///         case let .failure(error):
///             handleError(error)
///         }
///     }
///     .resume()
///
/// // Or DSL serialization with decoding
/// dataRequest
///     .responseDecodable(of: User.self) { result in
///         // Handle the decoded model
///     }
///     .resume()
/// ```
public final class DataRequest: BaseRequest, ResponseSerializable, @unchecked Sendable {
    
    /// A factory capable of rebuilding the original `URLRequest` before a retry.
    typealias RequestFactory = @Sendable () async throws(NetworkError) -> URLRequest
    
    private let requestFactory: RequestFactory
    private let responseSerializer: AnyResponseSerializer
    
    private nonisolated(unsafe) var completionHandler: ((DataRequestResult) -> Void)?
    private nonisolated(unsafe) var responseData = Data()
    
    init(
        session: URLSession,
        eventMonitor: NetworkEventMonitor,
        dataDecoder: AnyDataDecoder,
        initialRequest: URLRequest,
        requestFactory: @escaping RequestFactory,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        self.requestFactory = requestFactory
        responseSerializer = ResponseSerializer(dataDecoder: dataDecoder)
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
        responseData.removeAll(keepingCapacity: false)
    }
    
    override func recreateTask() async throws(NetworkError) -> URLSessionTask {
        let request = try await requestFactory()
        let task = session.dataTask(with: request)
        task.delegate = self
        return task
    }
    
    // MARK: - Legacy Response Handling
    
    /// Sets the request completion handler (legacy method).
    ///
    /// The handler is called when the request finishes (successfully or unsuccessfully).
    /// Returns `self` to support call chaining.
    ///
    /// - Parameter completionHandler: the closure that handles the result
    /// - Returns: `self` for call chaining
    @discardableResult
    public func onResponse(_ completionHandler: @escaping (DataRequestResult) -> Void) -> Self {
        self.completionHandler = completionHandler
        return self
    }
}

// MARK: - ResponseSerializable Implementation

extension DataRequest {
    
    /// Gets the raw response data.
    @discardableResult
    public func responseData(
        completionHandler: @escaping (Result<DataResponse, NetworkError>) -> Void
    ) -> Self {
        self.completionHandler = completionHandler
        resume()
        return self
    }
    
    /// Gets a JSON object from the response.
    public func responseJSON(
        completionHandler: @escaping (Result<Any, NetworkError>) -> Void
    ) -> Self {
        self.completionHandler = { result in
            switch result {
            case let .success(dataResponse):
                completionHandler(self.parse(dataResponse: dataResponse))
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
        resume()
        return self
    }
    
    /// Decodes the response into the specified model type.
    public func responseDecodable<Model: Decodable>(
        of type: Model.Type,
        decoder: JSONDecoder?,
        completionHandler: @escaping (Result<ModelResponse<Model>, NetworkError>) -> Void
    ) -> Self {
        self.completionHandler = { result in
            switch result {
            case let .success(dataResponse):
                completionHandler(self.parse(of: type, decoder: decoder, dataResponse: dataResponse))
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
        resume()
        return self
    }
    
    /// Asynchronously gets the raw response data.
    @discardableResult
    public func responseData() async throws(NetworkError) -> DataResponse {
        try await awaitResponse { handler in
            completionHandler = handler
        }
    }
    
    /// Asynchronously gets a JSON object from the response.
    public func responseJSON() async throws(NetworkError) -> Any {
        let dataResponse = try await responseData()
        return try responseSerializer.serializeJSON(dataResponse.data)
    }
    
    /// Asynchronously decodes the response into the specified model type.
    public func responseDecodable<Model: Decodable>(
        of type: Model.Type,
        decoder: JSONDecoder?
    ) async throws(NetworkError) -> ModelResponse<Model> {
        let dataResponse = try await responseData()
        return try responseSerializer.createModelResponse(
            from: dataResponse,
            of: type,
            using: decoder
        )
    }
}

// MARK: - URLSessionTaskDelegate

extension DataRequest: URLSessionTaskDelegate {
    
    /// Called when the task completes (successfully or with an error).
    ///
    /// Handles request completion, notifies the event monitor,
    /// and calls the completion handler with the result.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the request
    ///   - task: the request task
    ///   - error: the execution error, or `nil` on successful completion
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
        
        if let error {
            handleTaskError(error, task: task)
            return
        }
        
        guard let response = task.response,
              let httpResponse = response as? HTTPURLResponse else {
            completionHandler?(.failure(.invalidResponse(
                responseData,
                task.response ?? URLResponse()
            )))
            return
        }
        
        handleHTTPResponse(httpResponse, for: task)
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
    
    public func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        eventMonitor.request(
            task.safeRequest,
            didSendBodyData: bytesSent,
            totalBytesSent: totalBytesSent,
            totalBytesExpectedToSend: totalBytesExpectedToSend,
            requestID: requestID
        )
    }
}

// MARK: - URLSessionDataDelegate

extension DataRequest: URLSessionDataDelegate {
    
    /// Called when response data is received from the server.
    ///
    /// Accumulates the received data to build the final response.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the request
    ///   - dataTask: the data task
    ///   - data: the received data
    public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData.append(data)
        eventMonitor.request(
            dataTask.safeRequest,
            didReceiveData: data,
            requestID: requestID
        )
    }
}

// MARK: - Private

extension DataRequest {
    
    private func parse(dataResponse: DataResponse) -> Result<Any, NetworkError> {
        do {
            let json = try responseSerializer.serializeJSON(dataResponse.data)
            return .success(json)
        } catch {
            return .failure(error)
        }
    }
    
    private func parse<Model: Decodable>(
        of type: Model.Type,
        decoder: JSONDecoder?,
        dataResponse: DataResponse
    ) -> Result<ModelResponse<Model>, NetworkError> {
        do {
            let modelResponse = try responseSerializer.createModelResponse(
                from: dataResponse,
                of: type,
                using: decoder
            )
            return .success(modelResponse)
        } catch {
            return .failure(error)
        }
    }
    
    /// Handles a `URLSessionTask` error and initiates a retry when necessary.
    private func handleTaskError(_ error: any Error, task: URLSessionTask) {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            eventMonitor.requestDidCancel(task.safeRequest, requestID: requestID)
            completionHandler?(.failure(.explicitlyCancelled))
            return
        }
        
        Task {
            if await attemptRetry(response: task.response as? HTTPURLResponse, payload: .none, error: error) {
                return
            } else {
                eventMonitor.requestDidFail(task.safeRequest, error: error, requestID: requestID)
                completionHandler?(.failure(.executionFailed(error)))
            }
        }
    }
    
    /// Handles a successful HTTP response and decides whether a retry is needed.
    private func handleHTTPResponse(_ httpResponse: HTTPURLResponse, for task: URLSessionTask) {
        Task {
            await eventMonitor.requestDidReceive(
                task.safeRequest,
                response: httpResponse,
                data: responseData,
                requestID: requestID
            )
            
            let dataResponse = DataResponse(data: responseData, httpResponse: httpResponse)
            
            do {
                try validateResponse(dataResponse)
                eventMonitor.requestDidParseResponse(
                    task.safeRequest,
                    response: httpResponse,
                    data: responseData,
                    requestID: requestID
                )
                completionHandler?(.success(dataResponse))
            } catch let error as NetworkError {
                if await attemptRetry(response: httpResponse, payload: .data(responseData), error: error) {
                    return
                } else {
                    completionHandler?(.failure(error))
                }
            }
        }
    }
    
    /// Performs a retry with an optional "pre-hook", if the policy permits it.
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
            completionHandler?(.failure(retryError))
        } catch {
            completionHandler?(.failure(.executionFailed(error)))
        }
        
        return true
    }
    
    /// Verifies that the HTTP status is successful (2xx); otherwise throws an error.
    private func validateResponse(_ response: DataResponse) throws(NetworkError) {
        guard !response.status.isSuccess else { return }
        throw .unsuccessfulResponse(
            response.status,
            response.data
        )
    }
}

// swiftlint:enable file_length
