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

/// A wrapper for a network request response containing the raw data and HTTP metadata.
///
/// Used to obtain the raw data and access the HTTP response status.
public struct DataResponse: Sendable {
    
    /// The raw response bytes from the server.
    public let data: Data
    
    /// The HTTPURLResponse with headers, status code, etc.
    public let httpResponse: HTTPURLResponse

    /// The numeric HTTP response status code.
    public var statusCode: Int {
        httpResponse.statusCode
    }

    /// The wrapped HTTPStatus type for more readable work with statuses.
    public var status: HTTPStatus {
        HTTPStatus(statusCode: statusCode)
    }
}

/// A wrapper for a file download request response.
///
/// Contains the HTTP metadata and the URL of the downloaded file.
/// Used to obtain information about the downloaded file and access the HTTP response status.
public struct DownloadResponse: Sendable {
    
    /// The HTTPURLResponse with headers, status code, etc.
    public let httpResponse: HTTPURLResponse
    
    /// The URL of the downloaded file.
    ///
    /// Points to the temporary location of the file in the file system.
    public let fileUrl: URL
    
    /// The numeric HTTP response status code.
    public var statusCode: Int {
        httpResponse.statusCode
    }

    /// The wrapped HTTPStatus type for more readable work with statuses.
    public var status: HTTPStatus {
        HTTPStatus(statusCode: statusCode)
    }
}

/// A wrapper for a network request response with a decoded model.
///
/// Includes both the model itself and the metadata of the original response.
public struct ModelResponse<Model: Decodable & Sendable>: Sendable {

    /// The model decoded from the response body.
    public let model: Model
    
    /// The original response with the data and HTTP status.
    public let dataResponse: DataResponse

    /// The numeric HTTP response status code.
    public var statusCode: Int {
        dataResponse.statusCode
    }

    /// The wrapped HTTPStatus type for more readable work with statuses.
    public var status: HTTPStatus {
        HTTPStatus(statusCode: statusCode)
    }
}
