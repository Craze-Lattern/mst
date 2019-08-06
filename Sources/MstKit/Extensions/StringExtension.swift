//
//  StringExtension.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

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
}
