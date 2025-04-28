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

/// Represents the allowed value types for query parameters.
///
/// Strictly limits the set of types so that arbitrary values cannot be passed
/// into the URL: only strings, numbers, and booleans, as well as nested arrays
/// and dictionaries of the supported types.
public enum QueryValue: Sendable {

    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([QueryValue])
    case dictionary([String: QueryValue])
}

// MARK: - ExpressibleByStringLiteral

extension QueryValue: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension QueryValue: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

// MARK: - ExpressibleByFloatLiteral

extension QueryValue: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

// MARK: - ExpressibleByBooleanLiteral

extension QueryValue: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension QueryValue: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: QueryValue...) {
        self = .array(elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension QueryValue: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, QueryValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
