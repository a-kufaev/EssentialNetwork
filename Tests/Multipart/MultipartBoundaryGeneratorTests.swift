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

/// Unit tests for `MultipartBoundaryGenerator`.
///
/// Verifies the generation of unique and correctly formatted boundaries for multipart.
struct MultipartBoundaryGeneratorTests {
    
    @Test("Generates a string in the correct format")
    func testBoundaryFormat() throws {
        let generator = MultipartBoundaryGenerator()
        let boundary = generator.generate()
        let regex = try NSRegularExpression(pattern: "^boundary\\.[0-9a-f]{16}$")
        let range = NSRange(location: 0, length: boundary.utf16.count)
        #expect(regex.firstMatch(in: boundary, options: [], range: range) != nil)
    }

    @Test("Generates unique boundaries")
    func testBoundaryUniqueness() {
        let generator = MultipartBoundaryGenerator()
        var boundaries = Set<String>()
        for _ in 0 ..< 1000 {
            let boundary = generator.generate()
            #expect(!boundaries.contains(boundary))
            boundaries.insert(boundary)
        }
    }
}
