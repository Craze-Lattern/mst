//
//  Unused.swift
//  mst
//
//  Created by 郭源 on 2019/8/7.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant
import Curry
import Files
import Foundation
import MstKit
import Rainbow

public struct UnusedCommand: CommandProtocol {
    public struct Options: OptionsProtocol {
        public let path: String
        public let resourceExtensions: String
        public let fileExtensions: String
        public let exclude: String?
        public let output: String?

        // swiftlint:disable line_length
        public static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<ClientError>> {
            return curry(Options.init)
                <*> mode <| Argument(usage: "the project path")
                <*> mode <| Option(key: "resource-extensions", defaultValue: "imageset|jpg|png|gif", usage: "Resource file extensions need to be searched. Default is 'imageset|jpg|png|gif'")
                <*> mode <| Option(key: "file-extensions", defaultValue: "h|m|mm|swift|xib|storyboard|plist|json", usage: "In which types of files we should search for resource usage. Default is 'h|m|mm|swift|xib|storyboard|plist|json'")
                <*> mode <| Option(key: "exclude", defaultValue: nil, usage: "Exclude paths from search.")
                <*> mode <| Option(key: "output", defaultValue: nil, usage: "output html path")
        }
    }

    public let verb = "unused"
    public let function = "Find unused resources"

    public init() {}

    public func run(_ options: UnusedCommand.Options) -> Result<Void, MSError> {
        do {
            let outputs = try unused(
                options.path,
                resoureExtensions: options.resourceExtensions.components(separatedBy: "|"),
                fileExtensions: options.fileExtensions.components(separatedBy: "|"),
                exclude: options.exclude?.components(separatedBy: "|")
            )

            try output(
                .init(options.output),
                headers: outputs.header,
                bodys: outputs.body,
                footers: outputs.footer
            )
        } catch {
            if let error = error as? MSError {
                return .failure(error)
            }
            return .failure(.error(String(describing: error)))
        }
        return .success(())
    }
}

private extension UnusedCommand {
    // swiftlint:disable large_tuple
    func unused(
        _ path: String,
        resoureExtensions: [String],
        fileExtensions: [String],
        exclude: [String]?
    ) throws -> (header: [String], body: [OutputDescription], footer: [String]) {
        func usedStringNames(in files: Set<File>) throws -> Set<String> {
            let result = try files.reduce([String]()) { (result, file) throws -> [String] in
                try autoreleasepool { () -> [String] in
                    let content = try file.readAsString(encoding: .macOSRoman)
                    let matchRules = file.fileType?.matchRules(extensions: resoureExtensions) ?? [PlainImageMatchRule(extensions: resoureExtensions)]

                    var result = result
                    result.append(contentsOf: matchRules.flatMap {
                        $0.match(in: content).map { $0 }.filter { !$0.isEmpty }
                    })
                    return result
                }
            }
            return Set(result)
        }
        print("Searching all resources...".blue)
        let resources = try Process.find(in: path, extensions: resoureExtensions, exclude: exclude ?? [])
        print("Founded: " + "\(resources.count)".green + ";Total: " + String(size: resources.reduce(0) { $0 + $1.size() }).red)

        print("Searching unused file...".blue)
        guard let files = try Process.find(in: path, extensions: fileExtensions, exclude: exclude ?? []) as? Set<File> else {
            throw MSError.noneFileFound
        }

        let used = try usedStringNames(in: files)

        let results = resources.filter { (item) -> Bool in
            autoreleasepool { () -> Bool in
                let name = item.name.plainFileName(extensions: fileExtensions)
                return !used.contains(name) && !used.contains(where: { $0.similarPatternWithNumberIndex(other: name) })
            }
        }

        let headers = ["UnusedResources", "Size"]
        let body = Array(results).sorted()
        let footer = ["Total", String(size: results.reduce(0) { $0 + $1.size() })]

        return (headers, body, footer)
    }
}
