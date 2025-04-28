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

/// Unit tests for `MultipartBoundaryValidator`.
///
/// Verifies validation of multipart boundaries: length, allowed characters, and error propagation.
struct MultipartBoundaryValidatorTests {
    
    @Test("Validator accepts a valid boundary")
    func testValidBoundary() throws {
        let validator = MultipartBoundaryValidator()
        let valid = "boundary.12345678abcdEFGH"
        try validator.validate(valid)
    }

    @Test("Validator rejects a boundary that is too short")
    func testTooShortBoundary() {
        let validator = MultipartBoundaryValidator()
        let invalid = ""
        let expectedReason = "Length must be from 1 to 70 characters, got 0"
        #expect(throws: MultipartError.invalidBoundary(boundary: invalid, reason: expectedReason)) {
            try validator.validate(invalid)
        }
    }

    @Test("Validator rejects a boundary that is too long")
    func testTooLongBoundary() {
        let validator = MultipartBoundaryValidator()
        let invalid = String(repeating: "a", count: 71)
        let expectedReason = "Length must be from 1 to 70 characters, got 71"
        #expect(throws: MultipartError.invalidBoundary(boundary: invalid, reason: expectedReason)) {
            try validator.validate(invalid)
        }
    }

    @Test("Validator rejects a boundary with a space")
    func testBoundaryWithSpace() {
        let validator = MultipartBoundaryValidator()
        let invalid = "boundary with space"
        let expectedReason = makeValidationErrorReason(for: " ")
        #expect(throws: MultipartError.invalidBoundary(boundary: invalid, reason: expectedReason)) {
            try validator.validate(invalid)
        }
    }

    @Test("Validator rejects a boundary with a non-ASCII character")
    func testBoundaryWithNonAscii() {
        let validator = MultipartBoundaryValidator()
        let invalid = "boundary.тест"
        let char = "т"
        let expectedReason = makeValidationErrorReason(for: char)
        #expect(throws: MultipartError.invalidBoundary(boundary: invalid, reason: expectedReason)) {
            try validator.validate(invalid)
        }
    }

    @Test("Validator rejects a boundary with a quote")
    func testBoundaryWithQuote() {
        let validator = MultipartBoundaryValidator()
        let invalid = "boundary\"quote"
        let char = "\""
        let expectedReason = makeValidationErrorReason(for: char)
        #expect(throws: MultipartError.invalidBoundary(boundary: invalid, reason: expectedReason)) {
            try validator.validate(invalid)
        }
    }
    
    private func makeValidationErrorReason(for incorrectSymbol: String) -> String {
        """
        Character '\(incorrectSymbol)' (ASCII \(incorrectSymbol.first!.asciiValue ?? .zero)) is not allowed. \
        Only printable ASCII characters (33-126) are permitted, except spaces, quotes, and control characters
        """
    }
}
