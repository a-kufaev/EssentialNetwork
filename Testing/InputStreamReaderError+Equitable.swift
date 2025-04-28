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

extension InputStreamReaderError: Equatable {
    
    public static func == (lhs: InputStreamReaderError, rhs: InputStreamReaderError) -> Bool {
        switch (lhs, rhs) {
        case let (.openFailed(lhsStatus), .openFailed(rhsStatus)):
            return lhsStatus == rhsStatus
            
        case let (.readFailed(lhsBytes), .readFailed(rhsBytes)):
            return lhsBytes == rhsBytes
            
        case let (.sizeMismatch(lhsExpected, lhsActual), .sizeMismatch(rhsExpected, rhsActual)):
            return lhsExpected == rhsExpected && lhsActual == rhsActual
            
        case let (.streamError(lhsStatus), .streamError(rhsStatus)):
            return lhsStatus.localizedDescription == rhsStatus.localizedDescription
            
        default:
            return false
        }
    }
}
