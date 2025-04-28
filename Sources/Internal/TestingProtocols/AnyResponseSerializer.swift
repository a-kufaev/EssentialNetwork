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

protocol AnyResponseSerializer {

    func serializeJSON(_ data: Data) throws(NetworkError) -> Any
    // periphery:ignore - referenced by the ResponseSerializer implementation
    func decodeModel<Model: Decodable>(
        _ data: Data,
        to type: Model.Type,
        using decoder: JSONDecoder?
    ) throws(NetworkError) -> Model
    func createModelResponse<Model: Decodable>(
        from dataResponse: DataResponse,
        of type: Model.Type,
        using decoder: JSONDecoder?
    ) throws(NetworkError) -> ModelResponse<Model>
}

// swiftlint:enable all
