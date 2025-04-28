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

/// Unit tests for `MIMEType`.
///
/// Verifies the logic for determining MIME types from file extensions and working with custom types.
struct MIMETypeTests {
    
    @Test("Determines the MIME type from a file extension")
    func testFromPathExtension() {
        // Given
        let testCases: [(extension: String, expectedType: MIMEType?)] = [
            // Text files
            ("txt", .plainText),
            ("html", .html),
            ("htm", .html),
            ("css", .css),
            ("js", .javascript),
            
            // Images
            ("jpg", .jpeg),
            ("jpeg", .jpeg),
            ("png", .png),
            ("gif", .gif),
            ("webp", .webp),
            ("svg", .svg),
            
            // Audio
            ("mp3", .mp3),
            ("wav", .wav),
            ("aac", .aac),
            
            // Video
            ("mp4", .mp4),
            ("avi", .avi),
            ("mov", .mov),
            
            // Applications
            ("json", .json),
            ("xml", .xml),
            ("pdf", .pdf),
            ("zip", .zip),
            ("gz", .gzip),
            
            // Unknown extensions
            ("unknown", nil),
            ("xyz", nil),
            ("", nil)
        ]
        
        for testCase in testCases {
            // When
            let result = MIMEType.from(pathExtension: testCase.extension)
            
            // Then
            #expect(result == testCase.expectedType, "Failed for extension '\(testCase.extension)'")
        }
    }
    
    @Test("Handles extensions in different cases")
    func testFromPathExtensionCaseInsensitive() {
        // Given
        let testCases: [(extension: String, expectedType: MIMEType)] = [
            ("JPG", .jpeg),
            ("PNG", .png),
            ("PDF", .pdf),
            ("JSON", .json),
            ("HTML", .html),
            ("Mp4", .mp4),
            ("Mp3", .mp3)
        ]
        
        for testCase in testCases {
            // When
            let result = MIMEType.from(pathExtension: testCase.extension)
            
            // Then
            #expect(result == testCase.expectedType, "Failed for extension '\(testCase.extension)'")
        }
    }
    
    @Test("Handles edge cases")
    func testFromPathExtensionEdgeCases() {
        // Given/When/Then
        #expect(MIMEType.from(pathExtension: "") == nil) // Empty
        #expect(MIMEType.from(pathExtension: " jpg ") == nil) // With spaces
        #expect(MIMEType.from(pathExtension: "unknown") == nil) // Unknown extension
    }
}
