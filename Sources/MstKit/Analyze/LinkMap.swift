//
//  LinkMap.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/4.
//  Copyright © 2019 郭源. All rights reserved.
//

import Files
import Foundation
import Rainbow

public struct LinkMap {
    public class Object: CustomStringConvertible, OutputDescription {
        let name: String
        public private(set) var size: UInt
        let module: String?

        init(name: String = "", size: UInt = 0, module: String? = nil) {
            self.name = name
            self.size = size
            self.module = module
        }

        fileprivate func changeSize(_ newSize: UInt) {
            size = newSize
        }

        var fullName: String {
            var fullName = name
            if let module = module {
                fullName += "(\(module))"
            }
            return fullName
        }

        public var description: String {
            return "\(fullName): \(String(size: size))"
        }

        public var output: [String] {
            return [fullName, String(size: size)]
        }
    }

    let file: File

    public var name: String {
        return file.nameExcludingExtension
    }

    public init(path: String) throws {
        file = try File(path: path)
    }

    public func analyze(combineModules: Bool = true) throws -> [Object] {
        let content = try file.readAsString(encoding: .macOSRoman)

        print("Start analyze: " + file.path.lightGreen)
        defer {
            print("Finish analyze: " + file.path.lightGreen)
        }

        let objectFiles = self.objectFiles(in: content)
        print("Object Files: " + "\(objectFiles.count)".lightBlue)

        let symbols = self.symbols(in: content)
        print("Symbos: " + "\(symbols.count)".lightBlue)

        let objects = symbols
            .map { (symbol) -> Object in
                let object = objectFiles[symbol.key]!
                object.changeSize(symbol.value)
                return object
            }
            .filter { $0.size > 0 }

        return combineModules ? objects.combin() : objects
    }
}

/// Analyze
private extension LinkMap {
    static let numPattern = "\\[\\s*\\d*]\\s"

    /// Analyze sction `Composition.objectFiles`
    ///
    /// - Returns: [File Num: `Object`]
    func objectFiles(in content: String) -> [String: Object] {
        return Composition.objectFiles
            .clip(content)
            .reduce([String: Object]()) { (dict, line) -> [String: Object] in
                /// Match [num]
                guard let fileNumRange = (line <-> LinkMap.numPattern).first else {
                    return dict
                }

                let fileNum = String(line[fileNumRange])
                let fullName = String(line[fileNumRange.upperBound ..< line.endIndex])
                    .components(separatedBy: "/")
                    .last!

                var dict = dict
                guard let subRange = (fullName <-> "\\(.*\\.o\\)").first else {
                    dict[fileNum] = Object(name: fullName)
                    return dict
                }

                let moduleName = String(fullName[fullName.startIndex ..< subRange.lowerBound])
                let fileName = { () -> String in
                    var name = String(fullName[subRange])
                    name.removeFirst() // rm (
                    name.removeLast() // rm )
                    return name
                }()

                dict[fileNum] = Object(name: fileName, module: moduleName)

                return dict
            }
    }

    /// Analyze sction `Composition.symbols`
    ///
    /// - Returns: [File Num: File size]
    func symbols(in content: String) -> [String: UInt] {
        return Composition.symbols
            .clip(content)
            .reduce([String: UInt]()) { (dict, line) -> [String: UInt] in
                /// Match [num]
                guard let fileNumRange = (line <-> LinkMap.numPattern).first else {
                    return dict
                }

                /// [Address, Size]
                let size = { () -> UInt in
                    let hexSize = String(line[line.startIndex ..< fileNumRange.lowerBound])
                        .components(separatedBy: "\t")[1]
                    return strtoul(hexSize, nil, 16)
                }()

                let fileNum = String(line[fileNumRange])

                var dict = dict
                dict[fileNum] = size + (dict[fileNum] ?? 0)
                return dict
            }
    }
}

/// Composition
private extension LinkMap {
    enum Composition: String {
        case objectFiles = "# Object files:"
        case sections = "# Sections:"
        case symbols = "# Symbols:"

        func clip(_ content: String) -> [String] {
            let sectionString: String
            switch self {
            case .objectFiles:
                sectionString = content.clip(between: Composition.objectFiles.rawValue, Composition.sections.rawValue)
            case .sections:
                sectionString = content.clip(between: Composition.sections.rawValue, Composition.symbols.rawValue)
            case .symbols:
                sectionString = content.clip(between: Composition.symbols.rawValue)
            }
            return sectionString.components(separatedBy: .newlines)
        }
    }
}

public extension LinkMap {
    struct Compare: OutputDescription {
        let identifier: String
        let current: UInt
        let previous: UInt
        public var diff: Int {
            return Int(current) - Int(previous)
        }

        public var output: [String] {
            return [identifier, String(size: previous), String(size: current), String(size: diff)]
        }
    }
}

public extension Array where Element == LinkMap.Object {
    func combin() -> [Element] {
        return reduce([:]) { (dict, object) -> [String: UInt] in // combin modules
            var dict = dict
            let name = object.module ?? object.name

            dict[name] = object.size + (dict[name] ?? 0)
            return dict
        }
        .map { LinkMap.Object(name: $0.key, size: $0.value) }
    }

    func compare(_ objects: [Element], ignoreEqual: Bool = true) -> [LinkMap.Compare] {
        var objectsDict = objects.reduce([:]) { (dict, object) -> [String: UInt] in
            var dict = dict
            dict[object.name] = object.size
            return dict
        }

        var compares = map { (object) -> LinkMap.Compare? in
            let oldSize = objectsDict.removeValue(forKey: object.name) ?? 0
            if oldSize == object.size, ignoreEqual {
                return nil
            }
            return LinkMap.Compare(identifier: object.name, current: object.size, previous: oldSize)
        }.compactMap { $0 }

        compares.append(
            contentsOf: objectsDict.map {
                LinkMap.Compare(identifier: $0.key, current: 0, previous: $0.value)
            }
        )

        return compares
    }
}

extension LinkMap.Object: Comparable {
    public static func == (lhs: LinkMap.Object, rhs: LinkMap.Object) -> Bool {
        return lhs.size == rhs.size
    }

    public static func < (lhs: LinkMap.Object, rhs: LinkMap.Object) -> Bool {
        return lhs.size < rhs.size
    }

    public static func <= (lhs: LinkMap.Object, rhs: LinkMap.Object) -> Bool {
        return lhs.size <= rhs.size
    }

    public static func >= (lhs: LinkMap.Object, rhs: LinkMap.Object) -> Bool {
        return lhs.size >= rhs.size
    }

    public static func > (lhs: LinkMap.Object, rhs: LinkMap.Object) -> Bool {
        return lhs.size > rhs.size
    }
}

extension LinkMap.Compare: Comparable {
    public static func < (lhs: LinkMap.Compare, rhs: LinkMap.Compare) -> Bool {
        return lhs.diff < rhs.diff
    }

    public static func <= (lhs: LinkMap.Compare, rhs: LinkMap.Compare) -> Bool {
        return lhs.diff <= rhs.diff
    }

    public static func >= (lhs: LinkMap.Compare, rhs: LinkMap.Compare) -> Bool {
        return lhs.diff >= rhs.diff
    }

    public static func > (lhs: LinkMap.Compare, rhs: LinkMap.Compare) -> Bool {
        return lhs.diff > rhs.diff
    }
}
