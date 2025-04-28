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

final class InputStreamMock: InputStream, @unchecked Sendable {
    
    var customStatus: Stream.Status = .notOpen
    var customError: Error?
    var hasBytes: Bool = true
    
    var openCallCount: Int = 0
    var openHandler: (() -> Void)?
    override func open() {
        openCallCount += 1
        openHandler?()
    }
    
    var closeCallCount: Int = 0
    var closeHandler: (() -> Void)?
    override func close() {
        closeCallCount += 1
        closeHandler?()
    }
    
    var readCallCount: Int = 0
    var readHandler: ((UnsafeMutablePointer<UInt8>, Int) -> Int)?
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        readCallCount += 1
        if let handler = readHandler {
            return handler(buffer, len)
        }
        return 0
    }
    
    override var streamStatus: Stream.Status {
        customStatus
    }

    override var streamError: Error? {
        customError
    }

    override var hasBytesAvailable: Bool {
        hasBytes
    }
}
