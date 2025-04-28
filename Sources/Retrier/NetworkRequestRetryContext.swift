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

/// Additional data associated with a network request result, used to decide on a retry.
public enum NetworkRequestRetryPayload: Sendable {

    /// The retry does not require any additional payload.
    case none

    /// The response contains binary data (used for Data/Upload requests).
    case data(Data)

    /// The response is represented by a temporary file (used for Download requests).
    case file(URL)
}

/// The context passed to the retrier to make a decision.
public struct NetworkRequestRetryContext: Sendable {
    
    /// The request that finished.
    public let request: BaseRequest
    
    /// The HTTP response received from the server (if there was one).
    public let response: HTTPURLResponse?
    
    /// The number of the next attempt.
    public let nextAttempt: UInt
    
    /// Additional result data.
    public let payload: NetworkRequestRetryPayload
    
    public init(
        request: BaseRequest,
        response: HTTPURLResponse?,
        nextAttempt: UInt,
        payload: NetworkRequestRetryPayload
    ) {
        self.request = request
        self.response = response
        self.nextAttempt = nextAttempt
        self.payload = payload
    }
}
