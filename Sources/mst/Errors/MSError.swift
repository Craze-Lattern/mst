//
//  MSError.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant

public enum MSError: Error, Equatable, CustomStringConvertible {
    case noneFileFound
    case error(String)

    public var description: String {
        switch self {
        case let .error(error):
            return error
        case .noneFileFound:
            return "Found none of file"
        }
    }
}

public extension CommandProtocol {
    typealias ClientError = MSError
}

public extension OptionsProtocol {
    typealias ClientError = MSError
}
