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

/// Validates unique boundaries for multipart data.
///
/// A boundary must conform to the RFC 7578 standard:
/// - Length: from 1 to 70 characters
/// - Characters: ASCII only (codes 33-126, excluding spaces)
/// - Must not contain spaces, quotes, or control characters
/// - Must be unique within a single multipart message
struct MultipartBoundaryValidator: AnyMultipartBoundaryValidator {
    
    /// Validates a boundary according to RFC 7578.
    ///
    /// - Parameter boundary: the boundary to validate
    func validate(_ boundary: String) throws(MultipartError) {
        // Length check (1-70 characters)
        let acceptedBoundaryLengthRange = ClosedRange.acceptedBoundaryLength
        guard acceptedBoundaryLengthRange ~= boundary.count else {
            throw MultipartError.invalidBoundary(
                boundary: boundary,
                reason: """
                Length must be \
                from \(acceptedBoundaryLengthRange.lowerBound) to \(acceptedBoundaryLengthRange.upperBound) characters, \
                got \(boundary.count)
                """
            )
        }
        
        // Character check per RFC 7578:
        // - ASCII 33-126 only
        // - Spaces (32), quotes (34), control characters (< 32), and DEL (127) are not allowed
        for char in boundary {
            let asciiValue = char.asciiValue ?? 0
            let acceptedAsciiCodesRange = ClosedRange.acceptedAsciiCodes
            if !(acceptedAsciiCodesRange ~= asciiValue) || asciiValue == 32 || asciiValue == 34 || asciiValue < 32 ||
                asciiValue == 127 {
                throw MultipartError.invalidBoundary(
                    boundary: boundary,
                    reason: """
                    Character '\(char)' (ASCII \(asciiValue)) is not allowed. \
                    Only printable ASCII characters (33-126) are permitted, except spaces, quotes, and control characters
                    """
                )
            }
        }
    }
}

// MARK: - Constants

extension ClosedRange<UInt8> {
    
    fileprivate static let acceptedAsciiCodes: ClosedRange<UInt8> = 33 ... 126
}

extension ClosedRange<Int> {
    
    fileprivate static let acceptedBoundaryLength: ClosedRange<Int> = 1 ... 70
}
