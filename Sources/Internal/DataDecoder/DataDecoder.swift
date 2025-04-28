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

/// Decodes response data into models.
///
/// Uses `JSONDecoder` to convert `Data` into objects conforming to the `Decodable` protocol.
struct DataDecoder: AnyDataDecoder {
    
    /// The default JSON decoder.
    let jsonDecoder: JSONDecoder
    
    /// Decodes data into a model of the specified type.
    ///
    /// - Parameters:
    ///   - data: the data to decode
    ///   - jsonDecoder: an optional JSON decoder (if nil, the default one is used)
    /// - Returns: the decoded model
    /// - Throws: `NetworkError.responseDecodingFailed` if decoding fails
    func decode<Model: Decodable>(
        _ data: Data,
        as _: Model.Type,
        using jsonDecoder: JSONDecoder?
    ) throws(NetworkError) -> Model {
        let jsonDecoder = jsonDecoder ?? self.jsonDecoder
        do {
            return try jsonDecoder.decode(Model.self, from: data)
        } catch {
            throw .responseDecodingFailed(error)
        }
    }
}
