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

/// Unit tests for `QueryParametersEncoder`.
///
/// Verifies encoding of various parameter types (strings, numbers, arrays, nested dictionaries), correct
/// escaping, error handling, and edge cases.
struct QueryParametersEncoderTests {
    
    private let encoder: QueryParametersEncoder
    private let baseURL: URL!
    
    init() {
        encoder = QueryParametersEncoder()
        baseURL = URL(string: "https://api.example.com")
    }
    
    // MARK: - Basic parameter tests
    
    @Test("Should encode a simple string parameter")
    func testEncodeSimpleStringParameter() throws {
        // Given
        let parameters: QueryParameters = ["name": "John"]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        #expect(encodedRequest.url?.absoluteString == "https://api.example.com?name=John")
        #expect(
            encodedRequest
                .value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded; charset=utf-8"
        )
    }
    
    @Test("Should encode multiple simple parameters")
    func testEncodeMultipleSimpleParameters() throws {
        // Given
        let parameters: QueryParameters = [
            "name": "John",
            "age": 30,
            "active": true,
            "score": 95.5
        ]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        #expect(urlString?.contains("age=30") == true)
        #expect(urlString?.contains("name=John") == true)
        #expect(urlString?.contains("active=true") == true)
        #expect(urlString?.contains("score=95.5") == true)
        // Verify alphabetical order
        #expect(urlString?.range(of: "age=30&name=John") != nil)
    }
    
    // MARK: - Array parameter tests
    
    @Test("Should encode an array parameter")
    func testEncodeArrayParameter() throws {
        // Given
        let parameters: QueryParameters = ["tags": ["swift", "network", "testing"]]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        #expect(urlString?.contains("tags=swift") == true)
        #expect(urlString?.contains("tags=network") == true)
        #expect(urlString?.contains("tags=testing") == true)
    }
    
    @Test("Should encode a mixed array parameter")
    func testEncodeMixedArrayParameter() throws {
        // Given
        let parameters: QueryParameters = [
            "values": [1, "two", true, 3.14]
        ]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        #expect(urlString?.contains("values=1") == true)
        #expect(urlString?.contains("values=two") == true)
        #expect(urlString?.contains("values=true") == true)
        #expect(urlString?.contains("values=3.14") == true)
    }
    
    // MARK: - Special character tests
    
    @Test("Should encode special characters")
    func testEncodeSpecialCharacters() throws {
        // Given
        let parameters: QueryParameters = [
            "search": "hello world!",
            "email": "user@example.com",
            "path": "/api/v1/users"
        ]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        
        // Verify only the decoded values
        let components = URLComponents(string: urlString ?? "")
        let queryItems = components?.queryItems ?? []
        let decodedParams = Dictionary(uniqueKeysWithValues: queryItems.map { item in
            let key = item.name.removingPercentEncoding ?? item.name
            let value = item.value?.removingPercentEncoding ?? item.value ?? ""
            return (key, value)
        })
        
        #expect(decodedParams["search"] == "hello world!")
        #expect(decodedParams["email"] == "user@example.com")
        #expect(decodedParams["path"] == "/api/v1/users")
    }

    @Test("Should not double percent-encode an ISO8601 cursor")
    func testEncodeCursorDoesNotDoubleEncode() throws {
        // Given
        let parameters: QueryParameters = [
            "nextCursor": "2026-03-17T06:57:21.913742Z"
        ]
        let request = URLRequest(url: baseURL)

        // When
        let encodedRequest = try encoder.encode(request, with: parameters)

        // Then
        let urlString = try #require(encodedRequest.url?.absoluteString)
        #expect(urlString.contains("nextCursor=2026-03-17T06%3A57%3A21.913742Z"))
        #expect(urlString.contains("%253A") == false)
    }

    @Test("Should not double percent-encode nested keys")
    func testEncodeNestedKeyDoesNotDoubleEncode() throws {
        // Given
        let parameters: QueryParameters = [
            "user": [
                "name": "John"
            ]
        ]
        let request = URLRequest(url: baseURL)

        // When
        let encodedRequest = try encoder.encode(request, with: parameters)

        // Then
        let urlString = try #require(encodedRequest.url?.absoluteString)
        // Expect single escaping of the brackets: %5B and %5D, but not %255B/%255D
        #expect(urlString.contains("user%5Bname%5D=John"))
        #expect(urlString.contains("%255B") == false)
        #expect(urlString.contains("%255D") == false)
    }
    
    // MARK: - Edge cases
    
    @Test("Should correctly handle empty parameters")
    func testEncodeEmptyParameters() throws {
        // Given
        let parameters: QueryParameters = [:]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        #expect(encodedRequest.url?.absoluteString == baseURL.absoluteString)
    }
    
    @Test("Should throw invalidURL for a nil URL")
    func testEncodeNilURL() throws {
        // Given
        let parameters: QueryParameters = ["name": "John"]
        var request = URLRequest(url: URL.applicationDirectory)
        request.url = nil
        
        // When/Then
        #expect(throws: NetworkError.invalidURL) {
            _ = try encoder.encode(request, with: parameters)
        }
    }
    
    // MARK: - Comprehensive tests
    
    @Test("Should encode complex parameters")
    func testEncodeComplexParameters() throws {
        // Given
        let parameters: QueryParameters = [
            "user": [
                "name": "John Doe",
                "age": 30,
                "active": true,
                "scores": [95.5, 88.0, 92.3],
                "address": [
                    "city": "New York",
                    "zip": "10001",
                    "tags": ["home", "work"]
                ]
            ],
            "search": "hello world!",
            "page": 1,
            "limit": 20
        ]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        
        // Verify only the decoded values
        let components = URLComponents(string: urlString ?? "")
        let queryItems = components?.queryItems ?? []
        
        // Group parameters by key to handle arrays
        var groupedParams: [String: [String]] = [:]
        for item in queryItems {
            let key = item.name.removingPercentEncoding ?? item.name
            let value = item.value?.removingPercentEncoding ?? item.value ?? ""
            groupedParams[key, default: []].append(value)
        }
        
        // Verify simple parameters
        #expect(groupedParams["limit"]?.first == "20")
        #expect(groupedParams["page"]?.first == "1")
        #expect(groupedParams["search"]?.first == "hello world!")
        
        // Verify nested parameters
        #expect(groupedParams["user[name]"]?.first == "John Doe")
        #expect(groupedParams["user[age]"]?.first == "30")
        #expect(groupedParams["user[active]"]?.first == "true")
        #expect(groupedParams["user[address][city]"]?.first == "New York")
        #expect(groupedParams["user[address][zip]"]?.first == "10001")
        
        // Verify arrays
        let scores = groupedParams["user[scores]"] ?? []
        #expect(scores.count == 3)
        #expect(scores.contains("95.5"))
        #expect(scores.contains("88.0"))
        #expect(scores.contains("92.3"))
        
        let tags = groupedParams["user[address][tags]"] ?? []
        #expect(tags.count == 2)
        #expect(tags.contains("home"))
        #expect(tags.contains("work"))
    }
    
    // MARK: - Nested dictionary tests
    
    @Test("Should encode a nested dictionary")
    func testEncodeNestedDictionary() throws {
        // Given
        let parameters: QueryParameters = [
            "user": [
                "name": "John",
                "age": 30,
                "address": [
                    "city": "New York",
                    "zip": "10001"
                ]
            ]
        ]
        let request = URLRequest(url: baseURL)
        
        // When
        let encodedRequest = try encoder.encode(request, with: parameters)
        
        // Then
        let urlString = encodedRequest.url?.absoluteString
        #expect(urlString != nil)
        
        // Verify only the decoded values
        let components = URLComponents(string: urlString ?? "")
        #expect(components?.queryItems?.count == 4)
        
        let queryItems = components?.queryItems ?? []
        let decodedParams = Dictionary(uniqueKeysWithValues: queryItems.map { item in
            let key = item.name.removingPercentEncoding ?? item.name
            let value = item.value?.removingPercentEncoding ?? item.value ?? ""
            return (key, value)
        })
        
        #expect(decodedParams["user[name]"] == "John")
        #expect(decodedParams["user[age]"] == "30")
        #expect(decodedParams["user[address][city]"] == "New York")
        #expect(decodedParams["user[address][zip]"] == "10001")
    }
}
