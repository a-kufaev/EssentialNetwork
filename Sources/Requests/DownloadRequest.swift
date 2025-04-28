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

/// The result of downloading a file.
///
/// Contains either a successful response with the URL of the downloaded file,
/// or an error that occurred during the download.
public typealias DownloadResult = Result<DownloadResponse, NetworkError>

/// Manages the process of downloading a file from the server.
///
/// `DownloadRequest` provides full control over the download process:
/// - Starting, suspending, resuming, and cancelling the download
/// - Tracking download progress
/// - Handling results (success/error)
/// - The ability to resume an interrupted download
///
/// ## Usage example:
/// ```swift
/// let downloadRequest = try await session.download(
///     from: fileURL,
///     method: .get,
///     headers: nil,
///     parameters: nil,
///     interceptor: nil
/// )
///
/// downloadRequest
///     .onProgress { progress in
///         updateProgressBar(progress.fractionCompleted)
///     }
///     .onResponse { result in
///         switch result {
///         case let .success(response):
///             handleDownloadSuccess(response.fileUrl)
///         case let .failure(error):
///             handleDownloadError(error)
///         }
///     }
///     .resume()
/// ```
public final class DownloadRequest: BaseRequest, @unchecked Sendable {
    
    typealias RequestFactory = @Sendable () async throws(NetworkError) -> URLRequest
    
    private let downloadable: Downloadable
    
    private let fileManager: FileManager
    
    private nonisolated(unsafe) var progressHandler: ((Progress) -> Void)?
    private nonisolated(unsafe) var completionHandler: ((DownloadResult) -> Void)?
    
    enum Downloadable {
        
        case request(RequestFactory)
        case resumeData(Data)
    }
    
    private var downloadTask: URLSessionDownloadTask {
        // swiftlint:disable force_cast
        task as! URLSessionDownloadTask
        // swiftlint:enable force_cast
    }
    
    /// Determines the destination for the downloaded file.
    ///
    /// Lets you control where the downloaded file will be saved:
    /// - `.default` - the file is saved with the "Network\_" prefix in the default temporary folder
    /// - `.fileName(String)` - the file is saved with the specified name in the default temporary folder
    /// - `.url(URL)` - the file is saved at the specified path
    ///
    /// ## Usage example:
    /// ```swift
    /// // Saving with the default name
    /// let downloadRequest = try await session.download(
    ///     from: fileURL,
    ///     method: .get,
    ///     to: .default
    /// )
    ///
    /// // Saving with a custom name
    /// let downloadRequest = try await session.download(
    ///     from: fileURL,
    ///     method: .get,
    ///     to: .fileName("my_document.pdf")
    /// )
    ///
    /// // Saving to a specific folder
    /// let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    /// let destinationURL = documentsPath.appending(path: "downloads/report.pdf")
    /// let downloadRequest = try await session.download(
    ///     from: fileURL,
    ///     method: .get,
    ///     to: .url(destinationURL)
    /// )
    /// ```
    public enum Destination: Sendable {

        /// The file is saved with the "Network\_" prefix in the same folder as the source URL.
        /// For example, if the source file is named "document.pdf", the saved file will be "Network_document.pdf".
        case `default`
        
        /// The file is saved with the specified name in the same folder as the source URL.
        /// - Parameter fileName: the desired file name (including the extension)
        case fileName(String)
        
        /// The file is saved at the specified path.
        /// - Parameter url: the full URL for saving the file
        case url(URL)

        /// The file will attempt to be saved with the name specified in the request response. If that
        /// fails, the default name is used.
        case suggestName

        /// Computes the final URL for saving the file based on the chosen destination.
        ///
        /// - Parameters:
        ///   - origin: The source URL of the temporary file.
        ///   - suggest: The suggested file name. Used only for the `.suggestName` mode.
        ///     If `nil`, the default name will be used.
        /// - Returns: The final URL for saving the file.
        func url(for origin: URL, suggest: String? = nil) -> URL {
            let fallbackName = "Network_\(origin.lastPathComponent)"

            return switch self {
            case .default:
                origin.rename(to: fallbackName)
            case let .fileName(fileName):
                origin.rename(to: fileName)
            case .suggestName:
                origin.rename(to: suggest ?? fallbackName)
            case let .url(url):
                url
            }
        }
    }
    
    private let destination: Destination
    
    init(
        session: URLSession,
        fileManager: FileManager = .default,
        eventMonitor: NetworkEventMonitor,
        initialRequest: URLRequest,
        requestFactory: @escaping RequestFactory,
        to destination: Destination?,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        downloadable = .request(requestFactory)
        let task = session.downloadTask(with: initialRequest)
        self.fileManager = fileManager
        self.destination = destination ?? .default
        super.init(
            session: session,
            task: task,
            eventMonitor: eventMonitor,
            interceptors: interceptors,
            requestID: requestID
        )
        self.task.delegate = self
    }
    
    init(
        session: URLSession,
        fileManager: FileManager = .default,
        eventMonitor: NetworkEventMonitor,
        resumeData: Data,
        to destination: Destination?,
        interceptors: [NetworkRequestInterceptor],
        requestID: UUID
    ) {
        downloadable = .resumeData(resumeData)
        let task = session.downloadTask(withResumeData: resumeData)
        self.fileManager = fileManager
        self.destination = destination ?? .default
        super.init(
            session: session,
            task: task,
            eventMonitor: eventMonitor,
            interceptors: interceptors,
            requestID: requestID
        )
        self.task.delegate = self
    }
    
    override func recreateTask() async throws(NetworkError) -> URLSessionTask {
        let task: URLSessionDownloadTask
        switch downloadable {
        case let .request(makeRequest):
            let request = try await makeRequest()
            task = session.downloadTask(with: request)
        case let .resumeData(data):
            task = session.downloadTask(withResumeData: data)
        }
        task.delegate = self
        return task
    }
    
    /// Cancels the download with the ability to resume.
    ///
    /// The download can only be cancelled from the `.resumed` or `.suspended` states.
    /// Returns resume data for the download if the server supports this feature.
    /// This data can be used later to resume the download from the same place.
    ///
    /// ## Usage example:
    /// ```swift
    /// // Cancel the download and obtain the resume data
    /// let resumeData = await downloadRequest.cancelWithResumeData()
    ///
    /// // Later, resume the download with a new file name
    /// if let resumeData = resumeData {
    ///     let newDownloadRequest = session.download(
    ///         resumingWith: resumeData,
    ///         to: .fileName("resumed_document.pdf")
    ///     )
    ///     newDownloadRequest
    ///         .onProgress { progress in
    ///             print("Resumed download progress: \(progress.fractionCompleted)")
    ///         }
    ///         .onResponse { result in
    ///             switch result {
    ///             case let .success(response):
    ///                 print("Download completed: \(response.fileUrl)")
    ///             case let .failure(error):
    ///                 print("Download failed: \(error)")
    ///             }
    ///         }
    ///         .resume()
    /// }
    /// ```
    ///
    /// - Returns: the resume data for the download, or `nil` if the server does not support resuming
    /// - Note: The ability to resume depends on server support. Not all servers support this feature.
    public func cancelWithResumeData() async -> Data? {
        guard [.resumed, .suspended].contains(status) else { return nil }
        let resumeData = await downloadTask.cancelByProducingResumeData()
        status = .cancelled
        return resumeData
    }
    
    /// Sets the download progress handler.
    ///
    /// The handler is called on every download progress update.
    /// Returns `self` to support call chaining.
    ///
    /// - Parameter closure: the closure that handles progress
    /// - Returns: `self` for call chaining
    @discardableResult
    public func onProgress(_ closure: @escaping (Progress) -> Void) -> Self {
        progressHandler = closure
        return self
    }
    
    /// Sets the download completion handler.
    ///
    /// The handler is called when the download finishes (successfully or unsuccessfully).
    /// Returns `self` to support call chaining.
    ///
    /// - Parameter completionHandler: the closure that handles the result
    /// - Returns: `self` for call chaining
    @discardableResult
    public func onResponse(_ completionHandler: @escaping (DownloadResult) -> Void) -> Self {
        self.completionHandler = completionHandler
        return self
    }

    /// Waits for the download to finish and returns the result.
    ///
    /// Asynchronously waits for the download to finish and returns a `DownloadResponse`
    /// with the URL of the downloaded file, or throws an error. This method automatically
    /// starts the download if it has not been started yet.
    ///
    /// ## Usage example:
    /// ```swift
    /// do {
    ///     let response = try await downloadRequest.response()
    ///     print("File downloaded to: \(response.fileUrl)")
    ///
    ///     // The file is automatically saved to the specified destination
    ///     // and available at the response.fileUrl path
    /// } catch {
    ///     print("Download failed: \(error)")
    /// }
    /// ```
    ///
    /// ## Notes:
    /// - The method automatically calls `resume()` if the download has not been started
    /// - The file is saved to the specified destination (`.default`, `.fileName`, or `.url`)
    /// - In case of an error, the file is not saved and the temporary data is cleaned up
    ///
    /// - Returns: a response with the URL of the downloaded file
    /// - Throws: `NetworkError` in case of a download error
    public func response() async throws(NetworkError) -> DownloadResponse {
        try await awaitResponse { handler in
            completionHandler = handler
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadRequest: URLSessionDownloadDelegate {
    
    /// Called when the file download finishes.
    ///
    /// Handles successful download completion, updates progress,
    /// and calls the completion handler with the result. Automatically
    /// moves the file from its temporary location to the specified destination.
    ///
    /// ## Handling process:
    /// 1. Updates the download status to `.finished`
    /// 2. Sets the download progress to 100%
    /// 3. Moves the file to the specified destination (`.default`, `.fileName`, or `.url`)
    /// 4. Calls the completion handler with a successful result
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the download
    ///   - downloadTask: the download task
    ///   - location: the URL of the temporary file with the downloaded data
    public func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        status = .finished

        progress.completedUnitCount = progress.totalUnitCount
        progressHandler?(progress)
        
        guard let response = downloadTask.response else {
            completionHandler?(.failure(.invalidResponse(location.dataRepresentation, URLResponse())))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler?(.failure(.invalidResponse(location.dataRepresentation, response)))
            return
        }
        
        completeDownload(using: httpResponse, from: location, task: downloadTask)
    }
    
    /// Called when data is received during the download.
    ///
    /// Updates the download progress and calls the progress handler.
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the download
    ///   - downloadTask: the download task
    ///   - bytesWritten: the number of bytes received in this call
    ///   - totalBytesWritten: the total number of bytes downloaded
    ///   - totalBytesExpectedToWrite: the total file size in bytes
    public func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount += bytesWritten
        progressHandler?(progress)
        eventMonitor.request(
            downloadTask.safeRequest,
            didReceiveBytes: bytesWritten,
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite,
            requestID: requestID
        )
    }
    
    /// Called when the task completes (successfully or with an error).
    ///
    /// Handles download errors and notifies the event monitor.
    /// Distinguishes between a user-initiated cancellation and other execution errors.
    ///
    /// ## Error handling:
    /// - **User cancellation**: sets the status to `.cancelled` and notifies the event monitor
    /// - **Execution errors**: sets the status to `.finished` and calls the completion handler with the error
    /// - **Successful completion**: does nothing (handled in `didFinishDownloadingTo`)
    ///
    /// - Parameters:
    ///   - session: the URLSession performing the download
    ///   - task: the download task
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
        guard let error else { return }
        handleTaskError(error, task: task)
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

extension DownloadRequest {

    /// Completes the download by moving the temporary file to the target location.
    private func completeDownload(
        using response: HTTPURLResponse,
        from location: URL,
        task: URLSessionDownloadTask
    ) {
        let destination = destination.url(for: location, suggest: response.suggestedFilename)

        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            try fileManager.moveItem(at: location, to: destination)
            eventMonitor.requestDidParseResponse(
                task.safeRequest,
                response: response,
                data: destination.absoluteString.data(using: .utf8) ?? Data(),
                requestID: requestID
            )
            completionHandler?(.success(DownloadResponse(httpResponse: response, fileUrl: destination)))
        } catch {
            try? fileManager.removeItem(at: location)
            completionHandler?(.failure(
                .downloadedFileMoveFailed(error, source: location, destination: destination)
            ))
        }
    }

    /// Handles `URLSessionTask` errors.
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
    
    /// Performs a retry for the download.
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

// MARK: - Helpers

extension URL {

    /// Renames the file, keeping it in the same folder
    fileprivate func rename(to filename: String) -> URL {
        deletingLastPathComponent().appending(path: filename)
    }
}

// swiftlint:enable file_length
