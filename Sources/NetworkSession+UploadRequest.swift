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

// MARK: - Upload Requests

extension NetworkSession {
    
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
    ///   - interceptor: an interceptor for additional request adaptation and retries
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
    public func upload(
        _ data: Data,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, parameters: nil)
        let requestID = UUID()
        return try await buildUploadRequest(
            using: configuration,
            dataProvider: { data },
            interceptor: interceptor,
            requestID: requestID
        )
    }
    
    /// Creates a request to upload multipart data to the server with progress tracking.
    ///
    /// Initiates a multipart/form-data upload to the server. Returns an `UploadRequest` that lets you
    /// control the upload and track progress.
    ///
    /// - Parameters:
    ///   - container: the container holding the multipart data
    ///   - url: the destination URL
    ///   - method: the HTTP method (usually .post)
    ///   - headers: additional HTTP headers
    ///   - boundary: the boundary used to separate parts (generated automatically if nil)
    ///   - interceptor: an interceptor for additional request adaptation and retries
    /// - Returns: an `UploadRequest` for managing the upload
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// let container = MultipartDataContainer()
    ///     .addText(name: "title", value: "My Document")
    ///     .addFile(name: "document", filename: "report.pdf", contentType: .pdf, data: pdfData)
    ///
    /// let uploadRequest = try await session.upload(
    ///     multipartDataContainer: container,
    ///     to: uploadURL,
    ///     method: .post,
    ///     headers: nil,
    ///     boundary: nil,
    ///     interceptor: nil
    /// )
    ///
    /// uploadRequest
    ///     .responseDecodable(of: MyResponseModel.self) { result in
    ///         // Handle the result
    ///     }
    ///     .resume()
    /// ```
    public func upload(
        multipartDataContainer container: MultipartDataContainer,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        boundary: String?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest {
        let configuration = RequestConfiguration(url: url, method: method, headers: headers, parameters: nil)
        let requestID = UUID()
        return try await buildMultipartUploadRequest(
            using: configuration,
            multipartDataContainer: container,
            boundary: boundary,
            interceptor: interceptor,
            requestID: requestID
        )
    }
    
    /// Creates a request to upload multipart data using the builder pattern.
    ///
    /// A convenient way to create and upload multipart data in a single call.
    /// The builder lets you describe the structure of the multipart data declaratively.
    ///
    /// - Parameters:
    ///   - multipartDataBuilder: a closure that configures the multipart data
    ///   - url: the destination URL
    ///   - method: the HTTP method (usually .post)
    ///   - headers: additional HTTP headers
    ///   - boundary: the boundary used to separate parts (generated automatically if nil)
    ///   - interceptor: an interceptor for additional request adaptation and retries
    /// - Returns: an `UploadRequest` for managing the upload
    /// - Throws: `NetworkError` if building the request fails
    ///
    /// ## Usage example:
    /// ```swift
    /// let uploadRequest = try await session.upload(
    ///     multipartDataBuilder: { builder in
    ///         builder
    ///             .addText(name: "username", value: "john_doe")
    ///             .addFile(name: "avatar", filename: "photo.jpg", contentType: .jpeg, data: imageData)
    ///     },
    ///     to: uploadURL,
    ///     method: .post,
    ///     headers: nil,
    ///     boundary: nil,
    ///     interceptor: nil
    /// )
    ///
    /// // Async/await style
    /// let response = try await uploadRequest.responseJSON()
    /// print("Response: \(response)")
    /// ```
    public func upload(
        multipartDataBuilder: @Sendable (MultipartDataBuilder) -> Void,
        to url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        boundary: String?,
        interceptor: NetworkRequestInterceptor?
    ) async throws(NetworkError) -> UploadRequest {
        let builder = MultipartDataBuilder()
        multipartDataBuilder(builder)
        let container = builder.build()
        
        return try await upload(
            multipartDataContainer: container,
            to: url,
            method: method,
            headers: headers,
            boundary: boundary,
            interceptor: interceptor
        )
    }
}

// MARK: - Private

extension NetworkSession {
    
    /// Builds the request for uploading data.
    private func buildUploadRequest(
        using configuration: RequestConfiguration,
        dataProvider: @Sendable @escaping () -> Data,
        interceptor: NetworkRequestInterceptor?,
        requestID: UUID
    ) async throws(NetworkError) -> UploadRequest {
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestFactory = makeRequestFactory(
            configuration: configuration,
            encoder: nil,
            interceptors: interceptorsChain,
            requestID: requestID
        )
        let payloadFactory: @Sendable () async throws(NetworkError) -> (URLRequest, Data) = {
            let request = try await requestFactory()
            return (request, dataProvider())
        }
        let payload = try await payloadFactory()
        return UploadRequest(
            session: session,
            eventMonitor: eventMonitor,
            dataDecoder: dataDecoder,
            initialPayload: payload,
            payloadFactory: payloadFactory,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
    
    /// Builds the request for uploading multipart data.
    private func buildMultipartUploadRequest(
        using configuration: RequestConfiguration,
        multipartDataContainer container: MultipartDataContainer,
        boundary: String?,
        interceptor: NetworkRequestInterceptor?,
        requestID: UUID
    ) async throws(NetworkError) -> UploadRequest {
        let interceptorsChain = combinedInterceptors(with: interceptor)
        let requestFactory = makeRequestFactory(
            configuration: configuration,
            encoder: nil,
            interceptors: interceptorsChain,
            requestID: requestID
        )
        let payloadFactory = { @Sendable [weak self] () async throws(NetworkError) -> (URLRequest, Data) in
            guard let self else { throw NetworkError.explicitlyCancelled }
            let request = try await requestFactory()
            let (multipartRequest, multipartData) = try self.encodeMultipartData(
                container,
                into: request,
                boundary: boundary
            )
            return (multipartRequest, multipartData)
        }
        let payload = try await payloadFactory()
        return UploadRequest(
            session: session,
            eventMonitor: eventMonitor,
            dataDecoder: dataDecoder,
            initialPayload: payload,
            payloadFactory: payloadFactory,
            interceptors: interceptorsChain,
            requestID: requestID
        )
    }
    
    /// Encodes the multipart data into the request.
    ///
    /// Uses `MultipartDataEncoder` to encode the container into multipart/form-data format
    /// and update the `URLRequest` with the appropriate headers.
    ///
    /// - Parameters:
    ///   - container: the container holding the multipart data
    ///   - urlRequest: the original request
    ///   - boundary: the boundary used to separate parts
    /// - Returns: a tuple (updated URLRequest, encoded data)
    /// - Throws: `NetworkError.multipartError` if encoding fails
    private func encodeMultipartData(
        _ container: MultipartDataContainer,
        into urlRequest: URLRequest,
        boundary: String?
    ) throws(NetworkError) -> (URLRequest, Data) {
        do {
            return try multipartDataEncoder
                .encode(urlRequest, with: container, boundary: boundary, setContentLength: true)
        } catch {
            throw .multipartError(error)
        }
    }
}

// swiftlint:enable function_parameter_count
