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
protocol AnyDataDecoder: Sendable {

    func decode<Model: Decodable>(
        _ data: Data,
        as type: Model.Type,
        using jsonDecoder: JSONDecoder?
    ) throws(NetworkError) -> Model
}

// swiftlint:enable all
