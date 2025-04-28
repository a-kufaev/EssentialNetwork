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

/// The result of a decision about retrying a request.
public enum NetworkRequestRetryResult: Sendable {
    
    /// Retry immediately.
    case retry
    /// Retry after the specified delay.
    case retryWithDelay(TimeInterval)
    /// Do not retry the request and return the error.
    case doNotRetryWithError(any Error)
}
