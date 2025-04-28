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

@testable import EssentialNetwork
import Foundation
import Testing

/// Unit tests for `DataDecoder`.
///
/// Verifies decoding of JSON data into models, working with custom JSONDecoders, and handling of decoding errors.
struct DataDecoderTests {
    
    private let decoder: DataDecoder
    private let jsonDecoder: JSONDecoder
    
    init() {
        let jsonDecoder = JSONDecoder()
        decoder = DataDecoder(jsonDecoder: jsonDecoder)
        self.jsonDecoder = jsonDecoder
    }
    
    // MARK: - Successful decoding tests
    
    @Test("Should decode a model using the default JSONDecoder")
    func testDecodeWithDefaultDecoder() throws {
        // Given
        struct SimpleModel: Codable, Equatable {

            let name: String
            let age: Int
        }
        
        let json = """
        {
            "name": "John",
            "age": 30
        }
        """.data(using: .utf8)!
        
        // When
        let model = try decoder.decode(json, as: SimpleModel.self, using: nil)
        
        // Then
        #expect(model == SimpleModel(name: "John", age: 30))
    }
    
    @Test("Should decode a model using a custom JSONDecoder")
    func testDecodeWithCustomDecoder() throws {
        // Given
        struct DateModel: Codable, Equatable {

            let date: Date
        }
        
        let json = """
        {
            "date": "2024-05-10T12:00:00Z"
        }
        """.data(using: .utf8)!
        
        // Create a custom decoder with the ISO8601 strategy
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = .iso8601
        
        // When
        let model = try decoder.decode(json, as: DateModel.self, using: customDecoder)
        
        // Then
        // Verify the date was decoded specifically via ISO8601
        let expectedDate = try #require(ISO8601DateFormatter().date(from: "2024-05-10T12:00:00Z"))
        #expect(model.date == expectedDate)
        
        // Verify the default decoder was not used
        do {
            _ = try jsonDecoder.decode(DateModel.self, from: json)
            #expect(Bool(false), "The default decoder should not decode an ISO8601 date")
        } catch {
            #expect(error is DecodingError)
        }
    }
    
    // MARK: - Error handling tests
    
    @Test("Should wrap a decoding error in NetworkError")
    func testWrapDecodingError() throws {
        // Given
        struct SimpleModel: Codable {

            let name: String
        }
        
        let invalidJSON = "{".data(using: .utf8)!
        
        // When/Then
        do {
            _ = try decoder.decode(invalidJSON, as: SimpleModel.self, using: nil)
            #expect(Bool(false), "Expected a decoding error")
        } catch {
            if case let .responseDecodingFailed(decodingError) = error {
                #expect(decodingError is DecodingError)
            } else {
                #expect(Bool(false), "Expected a responseDecodingFailed error")
            }
        }
    }
    
    @Test("Should wrap a custom decoder error in NetworkError")
    func testWrapCustomDecoderError() throws {
        // Given
        struct DateModel: Codable {

            let date: Date
        }
        
        let json = """
        {
            "date": "invalid-date"
        }
        """.data(using: .utf8)!
        
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = .iso8601
        
        // When/Then
        do {
            _ = try decoder.decode(json, as: DateModel.self, using: customDecoder)
            #expect(Bool(false), "Expected a decoding error")
        } catch {
            if case let .responseDecodingFailed(decodingError) = error {
                #expect(decodingError is DecodingError)
                if case let .dataCorrupted(context) = decodingError as? DecodingError {
                    #expect(context.debugDescription.contains("Expected date string to be ISO8601-formatted."))
                } else {
                    #expect(Bool(false), "Expected a dataCorrupted error")
                }
            } else {
                #expect(Bool(false), "Expected a responseDecodingFailed error")
            }
        }
    }
}
