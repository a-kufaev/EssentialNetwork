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
@testable import EssentialNetworkTesting
import Foundation
import Testing

/// Unit tests for `BodyEncoder`.
///
/// Verifies serialization of objects to JSON, setting of headers, handling of encoding errors, and working with
/// optional/empty objects.
struct BodyEncoderTests {
    
    private let encoder: BodyEncoder
    private let baseURL: URL!
    
    init() {
        encoder = BodyEncoder(jsonEncoder: JSONEncoder())
        baseURL = URL(string: "https://api.example.com")
    }
    
    // MARK: - Basic encoding tests
    
    @Test("Should encode a simple object")
    func testEncodeSimpleObject() throws {
        // Given
        struct SimpleObject: Codable {

            let name: String
            let age: Int
            let isActive: Bool
        }
        
        let object = SimpleObject(name: "John", age: 30, isActive: true)
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: object, jsonEncoder: nil)
        
        // Then
        #expect(encodedRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        
        let decodedObject = try JSONDecoder().decode(SimpleObject.self, from: #require(encodedRequest.httpBody))
        #expect(decodedObject.name == "John")
        #expect(decodedObject.age == 30)
        #expect(decodedObject.isActive == true)
    }
    
    @Test("Should encode with a custom JSONEncoder")
    func testEncodeWithCustomJSONEncoder() throws {
        // Given
        struct DateObject: Codable {

            let date: Date
        }
        
        let date = Date(timeIntervalSince1970: 0)
        let object = DateObject(date: date)
        let request = URLRequest(url: baseURL)
        
        let customEncoder = JSONEncoder()
        customEncoder.dateEncodingStrategy = .iso8601
        
        // When
        let encodedRequest = try encoder.encode(request, with: object, jsonEncoder: customEncoder)
        
        // Then
        // Use a decoder with the same date decoding strategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedObject = try decoder.decode(DateObject.self, from: #require(encodedRequest.httpBody))
        #expect(decodedObject.date == date)
        
        // Verify the date is encoded in ISO8601
        let httpBody = try #require(encodedRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: httpBody) as? [String: String])
        #expect(json["date"] == "1970-01-01T00:00:00Z")
    }
    
    // MARK: - Complex object tests
    
    @Test("Should encode a complex object with nested structures")
    func testEncodeComplexObject() throws {
        // Given
        struct Address: Codable {

            let city: String
            let zip: String
        }
        
        struct User: Codable {

            let name: String
            let age: Int
            let address: Address
            let tags: [String]
            let scores: [Double]
        }
        
        let object = User(
            name: "John Doe",
            age: 30,
            address: Address(city: "New York", zip: "10001"),
            tags: ["swift", "network"],
            scores: [95.5, 88.0, 92.3]
        )
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: object, jsonEncoder: nil)
        
        // Then
        let decodedObject = try JSONDecoder().decode(User.self, from: #require(encodedRequest.httpBody))
        #expect(decodedObject.name == "John Doe")
        #expect(decodedObject.age == 30)
        #expect(decodedObject.address.city == "New York")
        #expect(decodedObject.address.zip == "10001")
        #expect(decodedObject.tags == ["swift", "network"])
        #expect(decodedObject.scores == [95.5, 88.0, 92.3])
    }
    
    // MARK: - Error handling tests
    
    @Test("Should throw bodyEncodingFailed on an encoding error")
    func testEncodeThrowsOnEncodingError() throws {
        // Given
        struct InvalidObject: Encodable {

            func encode(to _: Encoder) throws {
                throw InvalidObject.makeError()
            }
            
            static func makeError() -> Error {
                EncodingError.invalidValue("test", EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Test error"
                ))
            }
        }
        
        let object = InvalidObject()
        let request = URLRequest(url: baseURL)
        
        // When/Then
        #expect(throws: NetworkError.bodyEncodingFailed(InvalidObject.makeError())) {
            _ = try encoder.encode(request, with: object, jsonEncoder: nil)
        }
    }
    
    // MARK: - Edge case tests
    
    @Test("Should correctly encode an empty object")
    func testEncodeEmptyObject() throws {
        // Given
        struct EmptyObject: Codable {}
        let object = EmptyObject()
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: object, jsonEncoder: nil)
        
        // Then
        #expect(encodedRequest.httpBody == "{}".data(using: .utf8))
    }
    
    @Test("Should correctly encode an object with optional values")
    func testEncodeOptionalValues() throws {
        // Given
        struct OptionalObject: Codable {

            let name: String?
            let age: Int?
            let isActive: Bool?
        }
        
        let object = OptionalObject(name: nil, age: 30, isActive: nil)
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: object, jsonEncoder: nil)
        
        // Then
        let decodedObject = try JSONDecoder().decode(OptionalObject.self, from: #require(encodedRequest.httpBody))
        #expect(decodedObject.name == nil)
        #expect(decodedObject.age == 30)
        #expect(decodedObject.isActive == nil)
    }
}
