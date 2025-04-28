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

// swiftlint:disable all

/// A type-safe representation of an HTTP status.
///
/// Based on [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110).
public enum HTTPStatus: Codable, Equatable, Hashable, Sendable {

    // MARK: - 2xx: Success

    /// Successful request.
    case ok
    /// Resource created.
    case created
    /// Request accepted but not yet processed.
    case accepted
    /// Resource already reported earlier.
    case alreadyReported
    /// No content in the response.
    case noContent

    // MARK: - 4xx: Client Error

    /// Bad request.
    case badRequest
    /// Unauthorized.
    case unauthorized
    /// Access forbidden.
    case forbidden
    /// Resource not found.
    case notFound
    /// Request conflict.
    case conflict
    /// Cannot process the entity.
    case unprocessableEntity
    /// Upgrade required.
    case upgradeRequired
    /// Method not allowed.
    case methodNotAllowed
    /// Request timed out.
    case requestTimeout

    // MARK: - 5xx: Server Error

    /// Internal server error.
    case internalServerError
    /// Bad gateway.
    case badGateway
    /// Service unavailable.
    case serviceUnavailable
    /// Gateway did not respond in time.
    case gatewayTimeout

    // MARK: - Other

    /// Unknown or non-standard status.
    case other(Int)

    /// The numeric HTTP status code.
    public var code: Int {
        switch self {
        case .ok: 200
        case .created: 201
        case .accepted: 202
        case .alreadyReported: 208
        case .noContent: 204
        case .badRequest: 400
        case .unauthorized: 401
        case .forbidden: 403
        case .notFound: 404
        case .conflict: 409
        case .unprocessableEntity: 422
        case .upgradeRequired: 426
        case .methodNotAllowed: 405
        case .requestTimeout: 408
        case .internalServerError: 500
        case .badGateway: 502
        case .serviceUnavailable: 503
        case .gatewayTimeout: 504
        case let .other(value): value
        }
    }

    /// Initializes the status from a numeric code.
    ///
    /// If the code is unknown, it is stored in `.other`.
    /// - Parameter statusCode: the numeric HTTP status.
    public init(statusCode: Int) {
        switch statusCode {
        case 200: self = .ok
        case 201: self = .created
        case 202: self = .accepted
        case 204: self = .noContent
        case 208: self = .alreadyReported
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound
        case 405: self = .methodNotAllowed
        case 408: self = .requestTimeout
        case 409: self = .conflict
        case 422: self = .unprocessableEntity
        case 426: self = .upgradeRequired
        case 500: self = .internalServerError
        case 502: self = .badGateway
        case 503: self = .serviceUnavailable
        case 504: self = .gatewayTimeout
        default: self = .other(statusCode)
        }
    }

    /// Whether the status is successful (2xx).
    public var isSuccess: Bool {
        (200 ... 299).contains(code)
    }

    /// A client-side error (4xx).
    public var isClientError: Bool {
        (400 ... 499).contains(code)
    }

    /// A server-side error (5xx).
    public var isServerError: Bool {
        (500 ... 599).contains(code)
    }
}

// swiftlint:enable all
