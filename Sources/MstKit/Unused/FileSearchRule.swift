//
//  FileMatchRule.swift
//  MstKit
//
//  Created by 郭源 on 2019/8/7.
//  Copyright © 2019 郭源. All rights reserved.
//

import Foundation

public protocol FileMatchRule {
    func match(in content: String) -> Set<String>
}

public protocol RegPatternMatchRule: FileMatchRule {
    var extensions: [String] { get }
    var patterns: [String] { get }
}

public extension RegPatternMatchRule {
    func match(in content: String) -> Set<String> {
        var result = Set<String>()
        for pattern in patterns { // swiftlint:disable force_try
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

            let matches = regex.matches(in: content, options: [], range: content.range)

            matches.forEach { checkingResult in

                let range = Range(checkingResult.range(at: 1), in: content)!
                result.insert(String(content[range]).plainFileName(extensions: extensions))
            }
        }

        return Set(result)
    }
}

public struct JSONImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public var patterns: [String] {
        var patterns = [":\\s*\"(.*?)\""]
        if extensions.isEmpty {
            return patterns
        }
        let joinedExt = extensions.joined(separator: "|")
        patterns.append("\"(.+?)\\.(\(joinedExt))\"")
        return patterns
    }
}

public struct PlainImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public var patterns: [String] {
        if extensions.isEmpty {
            return []
        }

        let joinedExt = extensions.joined(separator: "|")
        return ["\"(.+?)\\.(\(joinedExt))\""]
    }

    public init(extensions: [String]) {
        self.extensions = extensions
    }
}

public struct ObjCImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public let patterns = ["@\"(.*?)\"", "\"(.*?)\""]
}

public struct SwiftImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public let patterns = ["\"(.*?)\""]
}

public struct XibImageMatchRule: RegPatternMatchRule {
    public let extensions = [String]()
    public let patterns = ["image name=\"(.*?)\"", "image=\"(.*?)\"", "value=\"(.*?)\""]
}

public struct PlistImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public let patterns = ["<key>UIApplicationShortcutItemIconFile</key>[^<]*<string>(.*?)</string>", ">(.*?)<"]
}

public struct PlistAppIconMatchRule: FileMatchRule {
    public let extensions: [String]

    public func match(in content: String) -> Set<String> {
        var result = Set<String>()

        let groupRegexStr = "<key>CFBundleIconFiles</key>[^<]*<array>([\\w\\W]*?)</array>"

        let matches = content <-> groupRegexStr

        let groupContents = matches.map { String(content[$0]) }

        guard groupContents.count > 0 else {
            return result
        }

        let itemRegexStr = "<string>(.*?)</string>"
        for itemContent in groupContents {
            for checkingResult in itemContent <-> itemRegexStr {
                let extracted = String(itemContent[checkingResult])
                result.insert(extracted.plainFileName(extensions: extensions))
            }
        }

        return result
    }
}

public struct PbxprojImageMatchRule: RegPatternMatchRule {
    public let extensions: [String] // swiftlint:disable line_length
    public let patterns = ["ASSETCATALOG_COMPILER_APPICON_NAME = \"?(.*?)\"?;", "ASSETCATALOG_COMPILER_COMPLICATION_NAME = \"?(.*?)\"?;"]
}

public struct HTMLImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public let patterns = ["img\\s+src=[\"\'](.*?)[\"\']"]
}

public struct JSImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public let patterns = ["[\"\']src[\"\'],\\s+[\"\'](.*?)[\"\']"]
}

public struct CSSImageMatchRule: RegPatternMatchRule {
    public let extensions: [String]
    public var patterns: [String] {
        guard !extensions.isEmpty else {
            return []
        }

        let ext = extensions.joined(separator: "|")
        return ["([a-zA-Z0-9_-]*)\\.(\(ext))"]
    }
}
