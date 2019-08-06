//
//  Version.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant
import Foundation
import MstKit

public struct VersionCommand: CommandProtocol {
    public let verb = "version"
    public let function = "Display the current version of mst"

    public init() {}

    public func run(_: NoOptions<MSError>) -> Result<Void, MSError> {
        print(Version.current.value)
        return .success(())
    }
}
