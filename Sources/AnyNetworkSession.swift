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

/// @mockable
public protocol AnyNetworkSession: Sendable {
    
    // MARK: - DataRequest
    
    /// Creates a request with query parameters and returns a `DataRequest` for control.
    ///
    /// Initiates an HTTP request with query parameters. Returns a `DataRequest` that lets you
    /// control the request lifecycle (suspend, resume, cancel).
    /// Use this for requests that require control over the execution process.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - parameters: query parameters for the URL
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
    /// - Returns: a `DataRequest` for managing the request
    /// - Throws: `NetworkError` if building the request fails
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
    /// dataRequest
    ///     .responseData { result in
    ///         switch result {
    ///         case let .success(response):
    ///             print("Response: \(response)")
    ///         case let .failure(error):
    ///             print("Error: \(error)")
    ///         }
    ///     }
    ///     .resume()
    /// ```
    func request(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataRequest
    
    /// Creates a request with a JSON body and returns a `DataRequest` for control.
    ///
    /// Initiates an HTTP request with JSON data in the body. Returns a `DataRequest` that lets you
    /// control the request lifecycle (suspend, resume, cancel).
    /// Use this for requests with JSON data that require control over the process.
    ///
    /// - Parameters:
    ///   - url: the request URL
    ///   - method: the HTTP method
    ///   - headers: additional HTTP headers
    ///   - body: the object to serialize as JSON in the request body
    ///   - encoder: the JSON encoder used to serialize the body
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
    /// - Returns: a `DataRequest` for managing the request
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// struct CreateUser: Encodable {
    ///     let name: String
    ///     let email: String
    /// }
    ///
    /// let user = CreateUser(name: "John", email: "john@example.com")
    /// let dataRequest = try await session.request(
    ///     URL(string: "https://api.example.com/users")!,
    ///     method: .post,
    ///     headers: nil,
    ///     body: user,
    ///     encoder: nil,
    ///     interceptor: nil
    /// )
    ///
    /// dataRequest
    ///     .responseDecodable(of: User.self) { result in
    ///         // Handle the decoded model
    ///     }
    ///     .resume()
    /// ```
    func request(
        _ url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: RequestBody?,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> DataRequest
    
    // MARK: - Upload Requests
    
    /// Creates a request to upload data to the server with progress tracking.
    ///
    /// Initiates a data upload to the server. Returns an `UploadRequest` that lets you
    /// control the upload (suspend, resume, cancel) and track progress.
    /// Use this to upload large files with control over the process.
    ///
    /// - Parameters:
    ///   - data: the data to upload
    ///   - url: the destination URL
    ///   - method: the HTTP method (usually .post or .put)
    ///   - headers: additional HTTP headers
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
    /// - Returns: an `UploadRequest` for managing the upload
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// let uploadRequest = try await session.upload(
    ///     imageData,
    ///     to: URL(string: "https://api.example.com/upload")!,
    ///     method: .post,
    ///     headers: ["Authorization": "Bearer token"],
    ///     interceptor: nil
    /// )
    ///
    /// uploadRequest
    ///     .onProgress { progress in
    ///         print("Upload progress: \(progress.fractionCompleted)")
    ///     }
    ///     .responseData { result in
    ///         switch result {
    ///         case let .success(response):
    ///             print("Upload completed with status: \(response.statusCode)")
    ///         case let .failure(error):
    ///             print("Upload failed: \(error)")
    ///         }
    ///     }
    ///     .resume()
    /// ```
    func upload(
        _ data: Data,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest
    
    /// Creates a request to upload multipart data to the server with progress tracking.
    ///
    /// Initiates a multipart/form-data upload to the server with control over the process.
    ///
    /// - Parameters:
    ///   - container: the container holding the multipart data
    ///   - url: the destination URL
    ///   - method: the HTTP method (usually .post)
    ///   - headers: additional HTTP headers
    ///   - boundary: the boundary used to separate parts (generated automatically if nil)
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
    /// - Returns: an `UploadRequest` for managing the upload
    /// - Throws: `NetworkError` if building the request fails
    func upload(
        multipartDataContainer container: MultipartDataContainer,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        boundary: String?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest
    
    /// Creates a request to upload multipart data using the builder pattern.
    ///
    /// A convenient way to create and upload multipart data in a single call.
    ///
    /// - Parameters:
    ///   - multipartDataBuilder: a closure that configures the multipart data
    ///   - url: the destination URL
    ///   - method: the HTTP method (usually .post)
    ///   - headers: additional HTTP headers
    ///   - boundary: the boundary used to separate parts (generated automatically if nil)
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
    /// - Returns: an `UploadRequest` for managing the upload
    /// - Throws: `NetworkError` if building the request fails
    func upload(
        multipartDataBuilder: @Sendable (MultipartDataBuilder) -> Void,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        boundary: String?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest
    
    // MARK: - Download Requests
    
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
    ///   - interceptor: an interceptor for additional request adaptation and retry handling
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
    func download(
        from url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        parameters: QueryParameters?,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination?
    ) async throws(NetworkError) -> DownloadRequest
    
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
    ///   - interceptor: an interceptor (adapter + retrier) for this specific request
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
    func download(
        from url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        body: RequestBody?,
        encoder: JSONEncoder?,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination?
    ) async throws(NetworkError) -> DownloadRequest
    
    /// Creates a request to resume a download using previously saved data.
    ///
    /// Allows you to resume an interrupted download using the data obtained when the previous
    /// request was cancelled. This is useful for large files when the connection may drop.
    ///
    /// - Parameter resumeData: the data for resuming the download, obtained on cancellation
    /// - Returns: a `DownloadRequest` for managing the resumed download
    ///
    /// ## Usage example:
    /// ```swift
    /// // On cancelling the download we obtain the data needed to resume it
    /// let resumeData = await downloadRequest.cancelWithResumeData()
    ///
    /// // Later we resume the download
    /// if let resumeData {
    ///     let resumedRequest = try await session.download(resumingWith: resumeData)
    ///     let response = try await resumedRequest.response()
    ///     print("Download completed: \(response.fileUrl)")
    /// }
    /// ```
    func download(
        resumingWith resumeData: Data,
        interceptor: NetworkRequestInterceptor?,
        to destination: DownloadRequest.Destination?
    ) -> DownloadRequest
    
    // MARK: - Other
    
    func cancelAllRequests() async
    
    func cleanupCookies()
}

// swiftlint:enable function_parameter_count
