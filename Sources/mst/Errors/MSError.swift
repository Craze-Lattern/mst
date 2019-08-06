//
//  MSError.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant

public enum MSError: Error, Equatable, CustomStringConvertible {
    case fileNotFound(String)
    case notFile(String)
    case error(String)

    public var description: String {
        switch self {
        case let .fileNotFound(path):
            return "\(path) not found"
        case let .notFile(path):
            return "\(path) not a file"
        case let .error(error):
            return error
        }
    }
}

public extension CommandProtocol {
    typealias ClientError = MSError
}

public extension OptionsProtocol {
    typealias ClientError = MSError
}
