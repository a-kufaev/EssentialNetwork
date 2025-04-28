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

// Disable swiftlint here because CI fails with the identifier_name lint error.
// swiftlint:disable all

import Foundation

/// @mockable
protocol AnyMultipartDataEncoder: Sendable {

    // periphery:ignore - Intended for future use
    func encode(_ multipartData: MultipartDataContainer, boundary: String?) throws(MultipartError) -> Data
    func encode(
        _ urlRequest: URLRequest,
        with multipartData: MultipartDataContainer,
        boundary: String?,
        setContentLength: Bool
    ) throws(MultipartError) -> (URLRequest, Data)
}

// swiftlint:enable all
