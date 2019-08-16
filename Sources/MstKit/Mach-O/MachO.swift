//
//  MachO.swift
//  MstKit
//
//  Created by 郭源 on 2019/8/15.
//  Copyright © 2019 郭源. All rights reserved.
//

import Files
import Foundation

public enum MachOError: Error, CustomStringConvertible {
    case notMachOType
    case commandError(String)
    case incorrectSection

    public var description: String {
        switch self {
        case .notMachOType:
            return "Input file not mach-o file"
        case let .commandError(command):
            return "Command error: \(command)"
        case .incorrectSection:
            return "Only support iphone target."
        }
    }
}

public struct MachO {
    let path: String

    let arch: String

    public init(path: String) throws {
        guard Process.file(path)?.contains("Mach-O") ?? false else {
            throw MachOError.notMachOType
        }

        guard let lipo = Process.lipo(path) else {
            throw MachOError.commandError("lipo")
        }

        self.path = path

        arch = { () -> String in
            var arch = "arm64"
            if lipo.contains("arm64") {
                arch = "arm64"
            } else if lipo.contains("armv7") {
                arch = "armv7"
            } else if lipo.contains("x86_64") {
                arch = "x86_64"
            }
            return arch
        }()
    }
}

public extension MachO {
    func uselessClass() throws -> Set<String> {
        guard let output = Process.otool(arguments: ["-arch", arch, "-V", "-o", path]) else {
            throw MachOError.commandError("otool")
        }

        let classListSection = "Contents of (__DATA,__objc_classlist) section"
        let classRefsSection = "Contents of (__DATA,__objc_classrefs) section"
        let superRefsSection = "Contents of (__DATA,__objc_superrefs) section"

        guard output.contains(classListSection) else {
            throw MachOError.incorrectSection
        }

        let regex = try NSRegularExpression(pattern: "_OBJC_CLASS_\\$_(.*)$", options: .caseInsensitive)

        var (classList, classRefs) = (Set<String>(), Set<String>())
        var (canAddToList, canAddToRefs) = (false, false)

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("Contents of") {
                if line.contains(classListSection) {
                    canAddToList = true
                } else if line.contains(classRefsSection) || line.contains(superRefsSection) {
                    canAddToList = false
                    canAddToRefs = true
                } else {
                    canAddToRefs = false
                    canAddToList = false
                }
            }

            guard canAddToList || canAddToRefs else {
                continue
            }

            if canAddToList {
                let matches = regex.matches(in: line, options: [], range: line.range)
                matches.forEach { checkingResult in
                    let range = Range(checkingResult.range(at: 1), in: line)!
                    let className = String(line[range])
                    if !className.hasPrefix("PodsDummy_") { // Exclude Pods Header
                        classList.insert(className)
                    }
                }
            }

            if canAddToRefs {
                let matches = regex.matches(in: line, options: [], range: line.range)
                matches.forEach { checkingResult in
                    let range = Range(checkingResult.range(at: 1), in: line)!
                    classRefs.insert(String(line[range]))
                }
            }
        }

        return classList.subtracting(classRefs)
    }

    func uselessFunction(linkMapPath: String) throws -> Set<String> {
        let methodNames = try LinkMap(path: linkMapPath).allFunctions()

        let methodRefs = try { () throws -> Set<String> in
            guard let methname = Process.otool(arguments: ["-v", "-s", "__DATA", "__objc_selrefs", path]) else {
                throw MachOError.commandError("otool")
            }
            let regex = try NSRegularExpression(pattern: "__TEXT:__objc_methname:(.*)$", options: .caseInsensitive)
            let result = methname.components(separatedBy: "\n").flatMap { (line) -> [String] in
                let matches = regex.matches(in: line, options: [], range: line.range)
                return matches.map { String(line[Range($0.range(at: 1), in: line)!]) }
            }
            return Set(result)
        }()

        let result = methodNames.filter { !methodRefs.contains($0.1) }.map { $0.0 }

        return Set(result)
    }
}
