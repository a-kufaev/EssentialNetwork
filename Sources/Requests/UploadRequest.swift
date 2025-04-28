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

/// The result of uploading a file to the server.
///
/// Contains either a successful response with data from the server,
/// or an error that occurred during the upload.
public typealias UploadResult = Result<DataResponse, NetworkError>

/// Manages the process of uploading a file to the server.
///
/// `UploadRequest` provides full control over the upload process:
/// - Starting, suspending, resuming, and cancelling the upload
/// - Tracking upload progress
/// - Handling results (success/error)
/// - A DSL interface for serializing responses
///
/// ## Usage example:
/// ```swift
/// let uploadRequest = try await session.uploadWithProgress(
///     data,
///     to: uploadURL,
///     method: .post,
///     headers: nil,
///     interceptor: nil
/// )
///
/// // Using the callback style
/// uploadRequest
///     .onProgress { progress in
///         updateProgressBar(progress.fractionCompleted)
///     }
///     .responseData { result in
///         switch result {
///         case let .success(response):
///             handleUploadSuccess(response)
///         case let .failure(error):
///             handleUploadError(error)
///         }
///     }
///     .resume()
///
/// // Or DSL serialization with decoding
/// uploadRequest
///     .responseDecodable(of: MyModel.self) { result in
///         // Handle the decoded model
///     }
///     .resume()
/// ```
public final class UploadRequest: BaseRequest, ResponseSerializable, @unchecked Sendable {
    
    typealias UploadPayload = (request: URLRequest, body: Data)
    typealias UploadPayloadFactory = @Sendable () async throws(NetworkError) -> UploadPayload
    
    private let payloadFactory: UploadPayloadFactory
    private let responseSerializer: AnyResponseSerializer
    
    private nonisolated(unsafe) var progressHandler: ((Progress) -> Void)?
    private nonisolated(unsafe) var completionHandler: ((UploadResult) -> Void)?
    private nonisolated(unsafe) var responseData = Data()
    
    init(
        session: URLSession,
        eventMonitor: NetworkEventMonitor,
        dataDecoder: AnyDataDecoder,
        initialPayload: UploadPayload,
        payloadFactory: @escaping UploadPayloadFactory,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        self.payloadFactory = payloadFactory
        responseSerializer = ResponseSerializer(dataDecoder: dataDecoder)
        let task = session.uploadTask(with: initialPayload.request, from: initialPayload.body)
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
        let payload = try await payloadFactory()
        let task = session.uploadTask(with: payload.request, from: payload.body)
        task.delegate = self
        return task
    }
    
    // MARK: - Progress Handling
    
    /// Sets the upload progress handler.
    ///
    /// The handler is called on every upload progress update.
    /// Returns `self` to support call chaining.
    ///
    /// - Parameter closure: the closure that handles progress
    /// - Returns: `self` for call chaining
    @discardableResult
    public func onProgress(_ closure: @escaping (Progress) -> Void) -> Self {
        progressHandler = closure
        return self
    }
    
    // MARK: - Legacy Response Handling
    
    /// Sets the upload completion handler (legacy method).
    ///
    /// The handler is called when the upload finishes (successfully or unsuccessfully).
    /// Returns `self` to support call chaining.
    ///
    /// - Parameter completionHandler: the closure that handles the result
    /// - Returns: `self` for call chaining
    @discardableResult
    public func onResponse(_ completionHandler: @escaping (UploadResult) -> Void) -> Self {
        self.completionHandler = completionHandler
        return self
    }
}

// MARK: - ResponseSerializable Implementation

extension UploadRequest {
    
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
    @discardableResult
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
    @discardableResult
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

extension UploadRequest: URLSessionTaskDelegate {
    
    /// Called when the task completes (successfully or with an error).
    ///
    /// Handles upload completion, notifies the event monitor,
    /// and calls the completion handler with the result.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the upload
    ///   - task: the upload task
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
        
        handleHTTPResponse(httpResponse, task: task)
    }
    
    /// Called when data is sent to the server.
    ///
    /// Updates the upload progress and calls the progress handler.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the upload
    ///   - task: the upload task
    ///   - bytesSent: the number of bytes sent in this call
    ///   - totalBytesSent: the total number of bytes sent
    ///   - totalBytesExpectedToSend: the total size of the data to send, in bytes
    public func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        progress.totalUnitCount = totalBytesExpectedToSend
        progress.completedUnitCount += bytesSent
        progressHandler?(progress)
        eventMonitor.request(
            task.safeRequest,
            didSendBodyData: bytesSent,
            totalBytesSent: totalBytesSent,
            totalBytesExpectedToSend: totalBytesExpectedToSend,
            requestID: requestID
        )
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

// MARK: - URLSessionDataDelegate

extension UploadRequest: URLSessionDataDelegate {
    
    /// Called when response data is received from the server.
    ///
    /// Accumulates the received data to build the final response.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the upload
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

extension UploadRequest {
    
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
    
    /// Handles a `URLSessionTask` error and initiates a retry when possible.
    private func handleTaskError(_ error: any Error, task: URLSessionTask) {
        Task {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                eventMonitor.requestDidCancel(task.safeRequest, requestID: requestID)
                completionHandler?(.failure(.explicitlyCancelled))
                return
            }
            
            if await attemptRetry(response: task.response as? HTTPURLResponse, payload: .none, error: error) {
                return
            } else {
                eventMonitor.requestDidFail(task.safeRequest, error: error, requestID: requestID)
                completionHandler?(.failure(.executionFailed(error)))
            }
        }
    }
    
    /// Handles a successful HTTP response.
    private func handleHTTPResponse(_ httpResponse: HTTPURLResponse, task: URLSessionTask) {
        Task {
            await eventMonitor.requestDidReceive(
                task.safeRequest,
                response: httpResponse,
                data: responseData,
                requestID: requestID
            )
            
            eventMonitor.requestDidParseResponse(
                task.safeRequest,
                response: httpResponse,
                data: responseData,
                requestID: requestID
            )
            completionHandler?(.success(DataResponse(data: responseData, httpResponse: httpResponse)))
        }
    }
    
    /// Starts a retry if the policy permits it.
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
}

// swiftlint:enable file_length
