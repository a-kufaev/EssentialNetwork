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

extension MultipartError: Equatable {

    public static func == (lhs: MultipartError, rhs: MultipartError) -> Bool {
        switch (lhs, rhs) {
        case let (.inputStreamCreationFailed(lhsURL), .inputStreamCreationFailed(rhsURL)):
            return lhsURL == rhsURL
            
        case let (.invalidFileURL(lhsURL), .invalidFileURL(rhsURL)):
            return lhsURL == rhsURL
            
        case let (.fileNotFound(lhsURL), .fileNotFound(rhsURL)):
            return lhsURL == rhsURL
            
        case let (.urlIsDirectory(lhsURL), .urlIsDirectory(rhsURL)):
            return lhsURL == rhsURL
            
        case let (.encodingFailed(lhsError), .encodingFailed(rhsError)):
            // Compare errors by their descriptions, since Error is not Equatable
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case let (.invalidBoundary(lhsBoundary, lhsReason), .invalidBoundary(rhsBoundary, rhsReason)):
            return lhsBoundary == rhsBoundary && lhsReason == rhsReason
            
        case let (.inputStreamReaderError(lhsError), .inputStreamReaderError(rhsError)):
            return lhsError == rhsError
            
        default:
            return false
        }
    }
}
