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

/// Generates unique boundaries for multipart data.
///
/// Generates a random boundary in the format "boundary.XXXXXXXXYYYYYYYY",
/// where X and Y are 8-character hex numbers (64 bits of randomness).
struct MultipartBoundaryGenerator: AnyMultipartBoundaryGenerator {
    
    /// Generates a new unique boundary.
    ///
    /// - Returns: a boundary string conforming to RFC 7578
    func generate() -> String {
        // Generate a random boundary: two UInt32 values in hex format
        // Format: "boundary.XXXXXXXXYYYYYYYY" (32 characters)
        let first = UInt32.random(in: UInt32.min ... UInt32.max)
        let second = UInt32.random(in: UInt32.min ... UInt32.max)
        
        return String(format: "boundary.%08x%08x", first, second)
    }
}
