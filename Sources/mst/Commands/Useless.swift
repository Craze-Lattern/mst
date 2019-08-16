//
//  Useless.swift
//  mst
//
//  Created by 郭源 on 2019/8/15.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant
import Curry
import MstKit

public struct UselessCommand: CommandProtocol {
    public struct Options: OptionsProtocol {
        public let path: String
        public let uselessFunctions: Bool
        public let linkMapPath: String

        public static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<ClientError>> {
            return curry(Options.init)
                <*> mode <| Argument(usage: "the Mach-O path")
                <*> mode <| Option(key: "useless-function", defaultValue: false, usage: "Find unused functions")
                <*> mode <| Option(key: "link-map", defaultValue: "", usage: "Use with useless-function")
        }
    }

    public let verb = "useless"
    public let function = "Find unused classes/functions. Default scan class."

    public init() {}

    public func run(_ options: UselessCommand.Options) -> Result<Void, MSError> {
        do {
            let machO = try MachO(path: options.path)
            let useless = options.uselessFunctions ?
                try machO.uselessFunction(linkMapPath: options.linkMapPath) :
                try machO.uselessClass()

            print("Unused:")
            print(useless.sorted().joined(separator: "\n"))
        } catch {
            if let error = error as? MSError {
                return .failure(error)
            }
            return .failure(.error(String(describing: error)))
        }

        return .success(())
    }
}
