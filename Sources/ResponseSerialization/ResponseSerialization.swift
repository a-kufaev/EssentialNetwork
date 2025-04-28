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

/// A serializer for handling various response types.
struct ResponseSerializer: AnyResponseSerializer {
    
    private let dataDecoder: AnyDataDecoder
    
    init(dataDecoder: AnyDataDecoder) {
        self.dataDecoder = dataDecoder
    }
    
    /// Serializes the data into a JSON object.
    func serializeJSON(_ data: Data) throws(NetworkError) -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw .responseDecodingFailed(error)
        }
    }
    
    /// Decodes the data into the specified model type.
    func decodeModel<Model: Decodable>(
        _ data: Data,
        to type: Model.Type,
        using decoder: JSONDecoder?
    ) throws(NetworkError) -> Model {
        try dataDecoder.decode(data, as: type, using: decoder)
    }
    
    /// Creates a `ModelResponse` from a `DataResponse`.
    func createModelResponse<Model: Decodable>(
        from dataResponse: DataResponse,
        of type: Model.Type,
        using decoder: JSONDecoder?
    ) throws(NetworkError) -> ModelResponse<Model> {
        let model = try decodeModel(dataResponse.data, to: type, using: decoder)
        return ModelResponse(model: model, dataResponse: dataResponse)
    }
}
