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

// MARK: - Download Requests

extension NetworkSession {
    
    /// Creates a request to download a file with query parameters.
    ///
    /// Initiates a file download from the server. Returns a `DownloadRequest` that lets you
    /// control the download (suspend, resume, cancel) and track progress.
    /// Use this to download large files with the ability to resume after a dropped connection.
    ///
    /// - Parameters:
    ///   - url: the URL of the file to download
    ///   - method: the HTTP method (usually .get)
    ///   - headers: additional HTTP headers
    ///   - parameters: query parameters for the URL
    ///   - interceptor: an interceptor for additional request adaptation and retries
    ///   - destination: the destination for the downloaded file (defaults to .default)
    /// - Returns: a `DownloadRequest` for managing the download
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// let downloadRequest = try await session.download(
    ///     from: URL(string: "https://api.example.com/files/document.pdf")!,
    ///     method: .get,
    ///     headers: ["Authorization": "Bearer token"],
    ///     parameters: ["version": "latest"],
    ///     interceptor: nil,
    ///     to: .fileName("my_document.pdf")
    /// )
    ///
    /// downloadRequest
    ///     .onProgress { progress in
    ///         print("Download progress: \(progress.fractionCompleted)")
    ///     }
    ///     .onResponse { result in
    ///         switch result {
    ///         case let .success(response):
    ///             print("File downloaded to: \(response.fileUrl)")
    ///         case let .failure(error):
    ///             print("Download failed: \(error)")
    ///         }
    ///     }
    ///     .resume()
    /// ```
    public func download(
        from url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination? = nil
    ) async throws(NetworkError) -> DownloadRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, parameters: parameters)
        let requestID = UUID()
        return try await buildDownloadRequest(
            using: configuration,
            encoder: nil,
            interceptor: interceptor,
            to: destination,
            requestID: requestID
        )
    }
    
    /// Creates a request to download a file with a JSON body.
    ///
    /// Similar to `download(from:method:headers:parameters:interceptor:to:)`, but allows sending
    /// JSON data in the request body. Useful for APIs that require parameters in the request body
    /// to initiate a download.
    ///
    /// - Parameters:
    ///   - url: the URL of the file to download
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - body: the object to serialize as JSON in the request body
    ///   - encoder: the JSON encoder used to serialize the body
    ///   - interceptor: an interceptor for additional request adaptation and retries
    ///   - destination: the destination for the downloaded file (defaults to .default)
    /// - Returns: a `DownloadRequest` for managing the download
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// struct DownloadParams: Encodable {
    ///     let fileId: String
    ///     let quality: String
    /// }
    ///
    /// let params = DownloadParams(fileId: "123", quality: "high")
    ///
    /// // Download with a custom file name
    /// let downloadRequest = try await session.download(
    ///     from: URL(string: "https://api.example.com/download")!,
    ///     method: .post,
    ///     headers: nil,
    ///     body: params,
    ///     encoder: nil,
    ///     interceptor: nil,
    ///     to: .fileName("high_quality_file.pdf")
    /// )
    ///
    /// let response = try await downloadRequest.response()
    /// print("File downloaded: \(response.fileUrl)")
    /// ```
    public func download(
        from url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: RequestBody?,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination? = nil
    ) async throws(NetworkError) -> DownloadRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, body: body)
        let requestID = UUID()
        return try await buildDownloadRequest(
            using: configuration,
            encoder: encoder,
            interceptor: interceptor,
            to: destination,
            requestID: requestID
        )
    }
    
    /// Creates a request to resume a download using previously saved data.
    ///
    /// Allows you to resume an interrupted download using the data obtained when the previous
    /// request was cancelled. This is useful for large files when the connection may drop.
    ///
    /// - Parameter resumeData: the data for resuming the download, obtained on cancellation
    /// - Parameter destination: the destination for the downloaded file (defaults to .default)
    /// - Returns: a `DownloadRequest` for managing the resumed download
    ///
    /// ## Usage example:
    /// ```swift
    /// // On cancelling the download we obtain the data needed to resume it
    /// let resumeData = await downloadRequest.cancelWithResumeData()
    ///
    /// // Later we resume the download with a new file name
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
    ///     }
    /// ```
    public func download(
        resumingWith resumeData: Data,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination? = nil
    ) -> DownloadRequest {
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestID = UUID()
        return DownloadRequest(
            session: session,
            eventMonitor: eventMonitor,
            resumeData: resumeData,
            to: destination,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
}

// MARK: - Private

extension NetworkSession {
    
    /// Builds the request.
    private func buildDownloadRequest(
        using configuration: RequestConfiguration,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination?,
        requestID: UUID
    ) async throws(NetworkError) -> DownloadRequest {
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestFactory = makeRequestFactory(
            configuration: configuration,
            encoder: encoder,
            interceptors: interceptorsChain,
            requestID: requestID
        )
        let request = try await requestFactory()
        return DownloadRequest(
            session: session,
            eventMonitor: eventMonitor,
            initialRequest: request,
            requestFactory: requestFactory,
            to: destination,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
}

// swiftlint:enable function_parameter_count
