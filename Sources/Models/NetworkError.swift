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

/// An enumeration of errors that occur at various stages of network interaction.
///
/// Represents all possible failures when building, sending, receiving, and handling HTTP requests and responses.
public enum NetworkError: Error {
    
    /// An invalid or missing URL when creating the request.
    case invalidURL
    
    /// Failed to serialize the request body to JSON.
    ///
    /// - associatedError: the original encoding error (Encodable).
    case bodyEncodingFailed(any Error)
    
    /// Failed to modify the request (adaptation, adding headers, etc.).
    ///
    /// - associatedError: the original adapter error.
    case requestAdaptationFailed(any Error)
    
    /// The server response does not match the expected HTTP format.
    ///
    /// - data: the raw response bytes;
    /// - response: the URLResponse object (often not an HTTPURLResponse).
    case invalidResponse(Data, URLResponse)
    
    /// An error while performing the network request (for example, an internal URLSession error).
    ///
    /// - associatedError: the original execution error.
    case executionFailed(any Error)

    /// An error while decoding the response body into a model.
    ///
    /// - associatedError: the original decoding error (Decodable).
    case responseDecodingFailed(any Error)
    
    /// An error while moving the downloaded file to its final destination.
    ///
    /// Occurs when the file is downloaded successfully to a temporary location but cannot be
    /// moved to the specified destination.
    ///
    /// - Parameters:
    ///   - error: the original error that occurred while moving the file
    ///   - source: the URL of the temporary file that could not be moved
    ///   - destination: the destination URL where the file could not be moved
    case downloadedFileMoveFailed(any Error, source: URL, destination: URL)
    
    /// The server returned a response with an unsuccessful status (not 2xx).
    ///
    /// This case is used when the server returns any status that is not successful (not in the 2xx range).
    /// For example:
    /// - 4xx - client errors (400 Bad Request, 401 Unauthorized, 403 Forbidden, etc.)
    /// - 5xx - server errors (500 Internal Server Error, 502 Bad Gateway, etc.)
    ///
    /// - Parameters:
    ///   - status: the HTTPStatus with the status code and category;
    ///   - data: the response body (Data), which may contain additional error information
    ///     (for example, JSON describing the cause of the error or a text message).
    case unsuccessfulResponse(HTTPStatus, Data)

    /// The request was explicitly cancelled.
    case explicitlyCancelled
    
    /// An error while working with multipart data.
    ///
    /// - associatedError: the original MultipartError.
    case multipartError(MultipartError)
}

// MARK: - Extensions

extension NetworkError {
    
    /// The underlying error, if any.
    public var underlyingError: (any Error)? {
        switch self {
        case .invalidURL, .invalidResponse, .unsuccessfulResponse, .explicitlyCancelled:
            nil
        case let .bodyEncodingFailed(error):
            error
        case let .requestAdaptationFailed(error):
            error
        case let .executionFailed(error):
            error
        case let .responseDecodingFailed(error):
            error
        case let .downloadedFileMoveFailed(error, _, _):
            error
        case let .multipartError(multipartError):
            multipartError.underlyingError
        }
    }
}
