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

/// A representation of an HTTP request method.
///
/// Stores a case-sensitive `String` value:
///
/// ```swift
/// HTTPMethod.get != HTTPMethod(rawValue: "get")
/// ```
///
/// Used to specify the type of HTTP request when communicating with the server.
///
/// See [RFC 7231 §4.3](https://tools.ietf.org/html/rfc7231#section-4.3).
public struct HTTPMethod: RawRepresentable, Hashable, Sendable {
    
    /// A safe HTTP method for retrieving the current representation of a resource.
    ///
    /// Does not change server state and is used to read data.
    ///
    /// See [RFC 7231 §4.3.1](https://tools.ietf.org/html/rfc7231#section-4.3.1).
    public static let get = HTTPMethod(rawValue: "GET")

    /// The same as `GET`, but without a body in the response.
    ///
    /// Often used to retrieve headers or check the status of a resource.
    ///
    /// See [RFC 7231 §4.3.2](https://tools.ietf.org/html/rfc7231#section-4.3.2).
    public static let head = HTTPMethod(rawValue: "HEAD")

    /// Sends data to the server to create or process a resource.
    ///
    /// May change server state.
    ///
    /// See [RFC 7231 §4.3.3](https://tools.ietf.org/html/rfc7231#section-4.3.3).
    public static let post = HTTPMethod(rawValue: "POST")

    /// Fully replaces the resource with the data from the request.
    ///
    /// See [RFC 7231 §4.3.4](https://tools.ietf.org/html/rfc7231#section-4.3.4).
    public static let put = HTTPMethod(rawValue: "PUT")

    /// Requests deletion of the specified resource.
    ///
    /// See [RFC 7231 §4.3.5](https://tools.ietf.org/html/rfc7231#section-4.3.5).
    public static let delete = HTTPMethod(rawValue: "DELETE")

    /// Partially updates a resource.
    ///
    /// Used to send only the changed data.
    ///
    /// See [RFC 5789](https://tools.ietf.org/html/rfc5789).
    public static let patch = HTTPMethod(rawValue: "PATCH")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - CustomStringConvertible

extension HTTPMethod: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}
