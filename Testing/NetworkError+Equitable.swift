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

extension NetworkError: Equatable {
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.explicitlyCancelled, .explicitlyCancelled):
            return true
            
        case let (.bodyEncodingFailed(lhsError), .bodyEncodingFailed(rhsError)),
             let (.requestAdaptationFailed(lhsError), .requestAdaptationFailed(rhsError)),
             let (.executionFailed(lhsError), .executionFailed(rhsError)),
             let (.responseDecodingFailed(lhsError), .responseDecodingFailed(rhsError)):
            // Compare errors by their descriptions, since Error is not Equatable
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case let (.invalidResponse(lhsData, lhsResponse), .invalidResponse(rhsData, rhsResponse)):
            // Compare the response data and URL
            return lhsData == rhsData && lhsResponse.url == rhsResponse.url
            
        case let (.unsuccessfulResponse(lhsStatus, lhsData), .unsuccessfulResponse(rhsStatus, rhsData)):
            return lhsStatus == rhsStatus && lhsData == rhsData
            
        case let (.multipartError(lhsError), .multipartError(rhsError)):
            return lhsError == rhsError
            
        default:
            return false
        }
    }
}
