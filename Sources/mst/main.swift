//
//  main.swift
//  mst
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant
import Foundation
import MstKit
import Rainbow

public struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

let registry = CommandRegistry<MSError>()

registry.register(AnalyzeCommand())
registry.register(VersionCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    print("[!] Error: ".red + String(describing: error))
}
