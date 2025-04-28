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

// MARK: - QueryValue + Equatable

extension QueryValue: Equatable {

    public static func == (lhs: QueryValue, rhs: QueryValue) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhs), .string(rhs)):
            return lhs == rhs
        case let (.int(lhs), .int(rhs)):
            return lhs == rhs
        case let (.double(lhs), .double(rhs)):
            return lhs == rhs
        case let (.bool(lhs), .bool(rhs)):
            return lhs == rhs
        case let (.array(lhs), .array(rhs)):
            return lhs == rhs
        case let (.dictionary(lhs), .dictionary(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
