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

extension String {
    
    /// Percent-escapes the string for safe inclusion in a URL according to RFC 3986.
    public var percentEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .rfcURLQueryAllowed) ?? self
    }
}

// MARK: - CharacterSet + RFC URL Query Allowed

extension CharacterSet {
    
    /// The set of characters allowed in a URL query per RFC 3986,
    /// minus the reserved GeneralDelims and SubDelims,
    /// which allows keys and values to be escaped correctly.
    fileprivate static let rfcURLQueryAllowed: CharacterSet = {
        let generalDelims = ":#[]@" // all except "?" and "/" per RFC 3986 - Section 3.4
        let subDelims = "!$&'()*+,;="
        let toEncode = CharacterSet(charactersIn: "\(generalDelims)\(subDelims)")
        return CharacterSet.urlQueryAllowed.subtracting(toEncode)
    }()
}
