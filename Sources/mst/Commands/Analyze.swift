//
//  Analyze.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Commandant
import Curry
import MstKit

public struct AnalyzeCommand: CommandProtocol {
    public struct Options: OptionsProtocol {
        public let path: String
        public let outputPath: String?
        public let previousPath: String?
        public let combinModules: Bool

        public static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<ClientError>> {
            return curry(Options.init)
                <*> mode <| Argument(usage: "the file to analyze")
                <*> mode <| Option(key: "output", defaultValue: nil, usage: "output html path")
                <*> mode <| Option(key: "compare", defaultValue: nil, usage: "another file to compare")
                <*> mode <| Option(key: "combin-modules", defaultValue: true, usage: "combine framework objects")
        }
    }

    public let verb = "analyze"
    public let function = "Analyze link map file"

    public init() {}

    public func run(_ options: AnalyzeCommand.Options) -> Result<Void, MSError> {
        do {
            let outpus = try analyze(options.path, aPath: options.previousPath, combinModules: options.combinModules)

            try LinkMap.output(
                .init(options.outputPath),
                headers: outpus.header,
                bodys: outpus.body,
                footers: outpus.footer
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

private extension AnalyzeCommand {
    // swiftlint:disable large_tuple
    func analyze(_ path: String, aPath: String?, combinModules: Bool) throws
        -> (header: [String], body: [OutputDescription], footer: [String]) {
        let linkMap = try LinkMap(path: path)
        let objects = try linkMap.analyze(combineModules: combinModules)
        guard let aPath = aPath else {
            let headers = ["Module", "Size"]
            let footers = ["Total", String(size: objects.reduce(0) { $0 + $1.size })]
            return (headers, objects.sorted().reversed(), footers)
        }
        let aLinkMap = try LinkMap(path: aPath)
        let compares = objects.compare(try aLinkMap.analyze(combineModules: combinModules))

        let headers = ["Module", aLinkMap.name, linkMap.name, "Diff"]
        let footers = ["Total", "", "", String(size: compares.reduce(0) { $0 + $1.diff })]

        return (headers, compares.sorted().reversed(), footers)
    }
}
