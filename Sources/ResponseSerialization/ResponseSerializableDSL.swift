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

/// A protocol for requests that support response serialization.
///
/// Provides a DSL interface for decoding responses into various formats.
public protocol ResponseSerializable: AnyObject {
    
    /// Retrieves the raw response data.
    ///
    /// Calls the handler with a `Result<DataResponse, NetworkError>`.
    ///
    /// - Parameter completionHandler: the handler for the raw response data
    /// - Returns: self, for call chaining
    @discardableResult
    func responseData(
        completionHandler: @escaping (Result<DataResponse, NetworkError>) -> Void
    ) -> Self
    
    /// Retrieves a JSON object from the response.
    ///
    /// Calls the handler with a `Result<Any, NetworkError>`, where `Any` is the JSON object.
    ///
    /// - Parameter completionHandler: the handler for the JSON response
    /// - Returns: self, for call chaining
    @discardableResult
    func responseJSON(
        completionHandler: @escaping (Result<Any, NetworkError>) -> Void
    ) -> Self
    
    /// Decodes the response into the specified model type.
    ///
    /// Calls the handler with a `Result<ModelResponse<Model>, NetworkError>`.
    ///
    /// - Parameters:
    ///   - type: the model type to decode into
    ///   - decoder: an optional JSON decoder
    ///   - completionHandler: the handler for the decoded response
    /// - Returns: self, for call chaining
    @discardableResult
    func responseDecodable<Model: Decodable>(
        of type: Model.Type,
        decoder: JSONDecoder?,
        completionHandler: @escaping (Result<ModelResponse<Model>, NetworkError>) -> Void
    ) -> Self
    
    /// Asynchronously retrieves the raw response data.
    ///
    /// - Returns: a `DataResponse` with the raw data
    /// - Throws: `NetworkError` if an error occurs
    func responseData() async throws(NetworkError) -> DataResponse
    
    /// Asynchronously retrieves a JSON object from the response.
    ///
    /// - Returns: the JSON object
    /// - Throws: `NetworkError` if an error occurs
    func responseJSON() async throws(NetworkError) -> Any
    
    /// Asynchronously decodes the response into the specified model type.
    ///
    /// - Parameters:
    ///   - type: the model type to decode into
    ///   - decoder: an optional JSON decoder
    /// - Returns: a `ModelResponse` with the decoded model
    /// - Throws: `NetworkError` if an error occurs
    func responseDecodable<Model: Decodable>(
        of type: Model.Type,
        decoder: JSONDecoder?
    ) async throws(NetworkError) -> ModelResponse<Model>
}

/// An extension with convenience methods for `ResponseSerializable`.
extension ResponseSerializable {
    
    /// Decodes the response into the specified model type using the default decoder.
    @discardableResult
    public func responseDecodable<Model: Decodable>(
        of type: Model.Type,
        completionHandler: @escaping (Result<ModelResponse<Model>, NetworkError>) -> Void
    ) -> Self {
        responseDecodable(of: type, decoder: nil, completionHandler: completionHandler)
    }
    
    /// Asynchronously decodes the response into the specified model type using the default decoder.
    public func responseDecodable<Model: Decodable>(
        of type: Model.Type
    ) async throws(NetworkError) -> ModelResponse<Model> {
        try await responseDecodable(of: type, decoder: nil)
    }
}

// swiftlint:enable all
