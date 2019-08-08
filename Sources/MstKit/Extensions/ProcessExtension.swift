//
//  ProcessExtension.swift
//  MstKit
//
//  Created by 郭源 on 2019/8/7.
//  Copyright © 2019 郭源. All rights reserved.
//

import Files
import Foundation

public extension Process {
    static func find(in path: String, extensions: [String], exclude: [String] = []) throws -> Set<FileSystem.Item> {
        let process = Process()

        process.launchPath = "/usr/bin/find"

        process.arguments = [path, "-type", "f", "("]
            + extensions.map { ["-o", "-name", "*.\($0)"] }.flatMap { $0 }.dropFirst()
            + [")"]
            + exclude.map { ["!", "-path", "*/\($0)/*"] }.flatMap { $0 }

        let outPipe = Pipe()
        process.standardOutput = outPipe

        process.launch()

        let outdata = outPipe.fileHandleForReading.readDataToEndOfFile()

        guard let outputString = String(data: outdata, encoding: .utf8) else { return [] }

        let result = try outputString
            .components(separatedBy: "\n")
            .dropLast()
            .compactMap(generate)
        return Set(result)
    }
}

private func generate(_ path: String) throws -> FileSystem.Item? {
    var isDir: ObjCBool = false
    FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
    if isDir.boolValue {
        return try Folder(path: path)
    } else {
        let file = try File(path: path)
        if file.name == "Contents.json", file.parent?.extension == "imageset" { // ignore Contents.json
            return nil
        }

        if let parent = file.parent, parent.extension == "imageset" {
            return parent
        }
        return file
    }
}
