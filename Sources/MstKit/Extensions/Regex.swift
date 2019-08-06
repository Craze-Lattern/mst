//
//  Regex.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Foundation

struct RegexHelper {
    let regex: NSRegularExpression

    init(_ pattern: String) throws {
        try regex = NSRegularExpression(pattern: pattern,
                                        options: .caseInsensitive)
    }

    func match(_ input: String) -> [Range<String.Index>] {
        let matches = regex.matches(in: input,
                                    options: [],
                                    range: NSRange(location: 0, length: input.utf16.count))

        return matches
            .map { Range($0.range, in: input) }
            .compactMap { $0 }
    }
}

precedencegroup MatchPrecedence {
    associativity: none
    higherThan: DefaultPrecedence
}

infix operator <->: MatchPrecedence

func <-> (lhs: String, rhs: String) -> [Range<String.Index>] {
    do {
        return try RegexHelper(rhs).match(lhs)
    } catch _ {
        return []
    }
}
