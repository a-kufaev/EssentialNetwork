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

extension HTTPHeader {
    
    /// Creates a `Content-Disposition` header.
    ///
    /// - Parameter value: the value of the `Content-Disposition` header
    /// - Returns: an HTTP header
    public static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Disposition", value: value)
    }
    
    /// Creates a `Content-Length` header.
    ///
    /// - Parameter value: the value of the `Content-Length` header
    /// - Returns: an HTTP header
    public static func contentLength(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Length", value: value)
    }

    /// Creates a `Content-Type` header.
    ///
    /// This header is usually set automatically when encoding the request body,
    /// so setting it manually may not be necessary.
    ///
    /// - Parameter value: the value of the `Content-Type` header
    /// - Returns: an HTTP header
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }
}
