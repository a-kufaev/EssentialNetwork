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

/// Unit tests for `String.percentEncoded`.
///
/// Verifies correct percent-encoding of strings, handling of special characters, Unicode, edge cases, and the
/// reversibility of encoding.
struct StringPercentEncodedTests {
    
    // MARK: - Basic encoding tests
    
    @Test("Should encode basic special characters")
    func testBasicEncoding() {
        let testCases: [(String, String)] = [
            ("hello world", "hello%20world"),
            ("user@example.com", "user%40example.com"),
            ("/api/v1/users", "/api/v1/users"),
            ("key[value]", "key%5Bvalue%5D"),
            ("a+b=c", "a%2Bb%3Dc"),
            ("", ""),
            ("normal text", "normal%20text")
        ]
        
        for (input, expected) in testCases {
            let encoded = input.percentEncoded
            #expect(
                encoded == expected,
                "Encoding error for '\(input)'. Expected '\(expected)', got '\(encoded)'"
            )
        }
    }
    
    @Test("Should encode complex special characters")
    func testComplexEncoding() {
        let testCases: [(String, String)] = [
            ("!@#$%^&*()", "%21%40%23%24%25%5E%26%2A%28%29"),
            ("привет мир", "%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80"),
            ("🌍 Hello", "%F0%9F%8C%8D%20Hello"),
            ("\n\t\r", "%0A%09%0D"),
            ("<>{}[]|\\", "%3C%3E%7B%7D%5B%5D%7C%5C")
        ]
        
        for (input, expected) in testCases {
            let encoded = input.percentEncoded
            #expect(
                encoded == expected,
                "Encoding error for '\(input)'. Expected '\(expected)', got '\(encoded)'"
            )
        }
    }
    
    // MARK: - Edge cases
    
    @Test("Should correctly handle an empty string")
    func testEmptyString() {
        let input = ""
        let encoded = input.percentEncoded
        #expect(encoded == "")
    }
    
    @Test("Should correctly handle a string without special characters")
    func testStringWithoutSpecialCharacters() {
        let input = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let encoded = input.percentEncoded
        #expect(encoded == input)
    }
    
    // MARK: - URL component tests
    
    @Test("Should correctly encode URL components")
    func testURLComponents() {
        let testCases: [(String, String)] = [
            ("query=value", "query%3Dvalue"),
            ("path/to/resource", "path/to/resource"),
            ("user:pass@host", "user%3Apass%40host"),
            ("?query=value&param=123", "?query%3Dvalue%26param%3D123"),
            ("#fragment", "%23fragment")
        ]
        
        for (input, expected) in testCases {
            let encoded = input.percentEncoded
            #expect(
                encoded == expected,
                "URL component encoding error for '\(input)'. Expected '\(expected)', got '\(encoded)'"
            )
        }
    }
    
    // MARK: - Encoding-decoding tests
    
    @Test("Should correctly decode back to the original string")
    func testRoundTrip() {
        let testCases = [
            "hello world",
            "user@example.com",
            "/api/v1/users",
            "key[value]",
            "a+b=c",
            "!@#$%^&*()",
            "привет мир",
            "🌍 Hello",
            "\n\t\r",
            "<>{}[]|\\"
        ]
        
        for input in testCases {
            let encoded = input.percentEncoded
            let decoded = encoded.removingPercentEncoding
            #expect(
                decoded == input,
                "Encoding/decoding error for '\(input)'. Encoded: '\(encoded)', decoded: '\(decoded ?? "nil")'"
            )
        }
    }
}
