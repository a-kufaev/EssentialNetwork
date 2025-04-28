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

/// MIME types for data.
///
/// Contains commonly used MIME types and the ability to specify custom values.
public enum MIMEType: Sendable, Equatable {
    
    // MARK: - Text Types
    
    /// Plain text.
    case plainText
    /// HTML document.
    case html
    /// CSS styles.
    case css
    /// JavaScript code.
    case javascript
    
    // MARK: - Image Types
    
    /// JPEG image.
    case jpeg
    /// PNG image.
    case png
    /// GIF image.
    case gif
    /// WebP image.
    case webp
    /// SVG image.
    case svg
    
    // MARK: - Audio Types
    
    /// MP3 audio.
    case mp3
    /// WAV audio.
    case wav
    /// AAC audio.
    case aac
    
    // MARK: - Video Types
    
    /// MP4 video.
    case mp4
    /// AVI video.
    case avi
    /// MOV video.
    case mov
    
    // MARK: - Application Types
    
    /// JSON data.
    case json
    /// XML data.
    case xml
    /// PDF document.
    case pdf
    /// ZIP archive.
    case zip
    /// ZIP archive.
    case gzip
    
    // MARK: - Custom Type
    
    /// A custom MIME type.
    case custom(String)
    
    /// The string representation of the MIME type.
    public var rawValue: String {
        switch self {
        case .plainText:
            return "text/plain; charset=utf-8"
        case .html:
            return "text/html; charset=utf-8"
        case .css:
            return "text/css; charset=utf-8"
        case .javascript:
            return "application/javascript; charset=utf-8"
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .gif:
            return "image/gif"
        case .webp:
            return "image/webp"
        case .svg:
            return "image/svg+xml"
        case .mp3:
            return "audio/mpeg"
        case .wav:
            return "audio/wav"
        case .aac:
            return "audio/aac"
        case .mp4:
            return "video/mp4"
        case .avi:
            return "video/x-msvideo"
        case .mov:
            return "video/quicktime"
        case .json:
            return "application/json"
        case .xml:
            return "application/xml"
        case .pdf:
            return "application/pdf"
        case .zip:
            return "application/zip"
        case .gzip:
            return "application/gzip"
        case let .custom(value):
            return value
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    /// Creates a MIME type from a file extension.
    ///
    /// - Parameter pathExtension: the file extension (for example, "jpg", "png")
    /// - Returns: the corresponding MIME type, or nil if none is found
    public static func from(pathExtension: String) -> MIMEType? {
        let ext = pathExtension.lowercased()
        switch ext {
        case "txt":
            return .plainText
        case "html", "htm":
            return .html
        case "css":
            return .css
        case "js":
            return .javascript
        case "jpg", "jpeg":
            return .jpeg
        case "png":
            return .png
        case "gif":
            return .gif
        case "webp":
            return .webp
        case "svg":
            return .svg
        case "mp3":
            return .mp3
        case "wav":
            return .wav
        case "aac":
            return .aac
        case "mp4":
            return .mp4
        case "avi":
            return .avi
        case "mov":
            return .mov
        case "json":
            return .json
        case "xml":
            return .xml
        case "pdf":
            return .pdf
        case "zip":
            return .zip
        case "gz":
            return .gzip
        default:
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
