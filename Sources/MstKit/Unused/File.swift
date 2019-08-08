//
//  File.swift
//  MstKit
//
//  Created by 郭源 on 2019/8/7.
//  Copyright © 2019 郭源. All rights reserved.
//

import Files
import Foundation

public extension FileSystem.Item {
    @objc func size() -> UInt {
        return 0
    }
}

extension File {
    public override func size() -> UInt {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: path),
            let size = attr[FileAttributeKey.size] as? UInt else {
            return 0
        }
        return size
    }
}

extension Folder {
    public override func size() -> UInt {
        return files.reduce(0) { $0 + $1.size() }
    }
}

public extension File {
    enum `Type` { // swiftlint:disable identifier_name
        case swift, objc, xib, plist, pbxproj, json, html, js, css

        init?(ext: String) {
            switch ext {
            case "swift": self = .swift
            case "h", "m", "mm": self = .objc
            case "xib", "storyboard": self = .xib
            case "plist": self = .plist
            case "pbxproj": self = .pbxproj
            case "json": self = .json
            case "html": self = .html
            case "js": self = .js
            case "css": self = .css
            default: return nil
            }
        }

        // swiftlint:disable line_length
        public func matchRules(extensions: [String]) -> [FileMatchRule] {
            switch self {
            case .swift: return [SwiftImageMatchRule(extensions: extensions)]
            case .objc: return [ObjCImageMatchRule(extensions: extensions)]
            case .xib: return [XibImageMatchRule()]
            case .plist: return [PlistImageMatchRule(extensions: extensions), PlistAppIconMatchRule(extensions: extensions)]
            case .pbxproj: return [PbxprojImageMatchRule(extensions: extensions)]
            case .json: return [JSONImageMatchRule(extensions: extensions)]
            case .html: return [HTMLImageMatchRule(extensions: extensions)]
            case .js: return [JSImageMatchRule(extensions: extensions)]
            case .css: return [CSSImageMatchRule(extensions: extensions)]
            }
        }
    }

    var fileType: `Type`? {
        return Type(ext: `extension` ?? "")
    }
}

extension FileSystem.Item: Hashable, Comparable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    public static func < (lhs: FileSystem.Item, rhs: FileSystem.Item) -> Bool {
        return lhs.name < rhs.name
    }
}

extension FileSystem.Item: OutputDescription {
    public var output: [String] {
        return [name, String(size: size())]
    }
}
