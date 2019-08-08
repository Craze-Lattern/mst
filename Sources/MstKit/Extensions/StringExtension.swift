//
//  StringExtension.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Files
import Foundation

private let byte = 1024.0
private let kiloByte = byte * byte
private let megaByte = kiloByte * kiloByte

public extension String {
    init(size: UInt, positive: Bool = true) {
        let dSize = Double(size)
        var sizeString = positive ? "" : "-"
        switch dSize {
        case 0 ..< byte:
            sizeString += "\(dSize)B"
        case byte ..< kiloByte:
            sizeString += String(format: "%.3fK", dSize / byte)
        default:
            sizeString += String(format: "%.3fM", dSize / kiloByte)
        }
        self = sizeString
    }

    init(size: Int) {
        self.init(size: UInt(abs(size)), positive: size >= 0)
    }

    func clip(between start: String? = nil, _ end: String? = nil) -> String {
        var (startIndex, endIndex) = (self.startIndex, self.endIndex)
        if let start = start, let range = range(of: start) {
            startIndex = range.upperBound
        }
        if let end = end, let range = range(of: end) {
            endIndex = range.lowerBound
        }

        return String(self[startIndex ..< endIndex])
    }

    var range: NSRange {
        return NSRange(location: 0, length: NSString(string: self).length)
    }
}

// swiftlint:disable force_try
let digitalRex = try! NSRegularExpression(pattern: "(\\d+)", options: .caseInsensitive)
public extension String {
    func plainFileName(extensions _: [String]) -> String {
        var result = NSString(string: self).deletingPathExtension
        if result.hasSuffix("@2x") || result.hasSuffix("@3x") || result.hasSuffix("@1x") {
            let endIndex = result.index(result.endIndex, offsetBy: -3)
            result = String(result[..<endIndex])
        }
        return result
    }

    // swiftlint:disable identifier_name
    func similarPatternWithNumberIndex(other: String) -> Bool {
        let matches = digitalRex.matches(in: other, options: [], range: other.range)
        // No digital found in resource key.
        guard matches.count >= 1 else { return false }
        let lastMatch = matches.last!
        let digitalRange = lastMatch.range(at: 1)

        var prefix: String?
        var suffix: String?

        let digitalLocation = digitalRange.location
        if digitalLocation != 0 {
            let index = other.index(other.startIndex, offsetBy: digitalLocation)
            prefix = String(other[..<index])
        }

        let digitalMaxRange = NSMaxRange(digitalRange)
        if digitalMaxRange < other.utf16.count {
            let index = other.index(other.startIndex, offsetBy: digitalMaxRange)
            suffix = String(other[index...])
        }

        switch (prefix, suffix) {
        case (nil, nil):
            return false // only digital
        case let (p?, s?):
            return hasPrefix(p) && hasSuffix(s)
        case (let p?, nil):
            return hasPrefix(p)
        case (nil, let s?):
            return hasSuffix(s)
        }
    }
}
