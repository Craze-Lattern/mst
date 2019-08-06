//
//  Template.swift
//  MsKit
//
//  Created by 郭源 on 2019/8/5.
//  Copyright © 2019 郭源. All rights reserved.
//

import Foundation

public protocol OutputDescription {
    var output: [String] { get }
}

public extension LinkMap {
    enum Output {
        case html(String), console

        public init(_ path: String? = nil) {
            if let path = path {
                self = .html(path)
            } else {
                self = .console
            }
        }
    }

    static func output(_ type: Output, headers: [String], bodys: [OutputDescription], footers: [String]? = nil) throws {
        func console() {
            let headerString = headers.joined(separator: "\t\t")
            let bodyString = bodys
                .map { $0.output.joined(separator: "\t\t") }
                .joined(separator: "\n")
            let footerString = footers?.joined(separator: "\t\t") ?? ""
            print([headerString, bodyString, footerString].joined(separator: "\n"))
        }

        func html(_ path: String) throws {
            let header = HTML.Tag.tr.autoClourse(headers.map { HTML.Tag.th.autoClourse($0) }.joined())
            let body = bodys
                .map { $0.output }
                .map { body in
                    HTML.Tag.tr.autoClourse(body.map { HTML.Tag.td.autoClourse($0) }.joined())
                }
                .joined()
            let footer = footers?
                .map { HTML.Tag.td.autoClourse($0) }
                .joined() ?? ""

            try template
                .replacingOccurrences(of: HTML.Composition.header.rawValue, with: header)
                .replacingOccurrences(of: HTML.Composition.body.rawValue, with: body)
                .replacingOccurrences(of: HTML.Composition.footer.rawValue, with: footer)
                .write(toFile: path, atomically: true, encoding: .utf8)

            print("Output: " + path.lightGreen)
        }
        guard case let .html(path) = type else {
            console()
            return
        }
        try html(path)
    }
}

struct HTML {
    fileprivate enum Tag: String { // swiftlint:disable identifier_name
        case tr, th, td

        func autoClourse(_ content: String) -> String {
            return "<\(rawValue)>\(content)</\(rawValue)>"
        }
    }

    fileprivate enum Composition: String {
        case header = "#HEADER#"
        case footer = "#FOOTER#"
        case body = "#BODY#"
    }
}

private let template = """
<!DOCTYPE html>
<html>

<head>
<meta charset="utf-8">
<style>
#table {
font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
border-collapse: collapse;
width: 100%;
}

#table td,
#table th {
border: 1px solid #ddd;
padding: 8px;
}

#table tr:nth-child(even) {
background-color: #f2f2f2;
}

#table tr:hover {
background-color: #ddd;
}

#table th {
padding-top: 12px;
padding-bottom: 12px;
text-align: left;
background-color: #4CAF50;
color: white;
}

#table tr.increase {
color: red;
}

#table tr.decrease {
color: green
}
</style>
<script>
function calculation() {
const table = document.getElementById("table")
const rows = table.rows
for (const row in rows) {
if (rows.hasOwnProperty(row)) {
const element = rows[row];
const lastCell = element.cells[element.cells.length - 1]
if (lastCell.textContent.startsWith("-")) {
element.className = "decrease"
} else {
element.className = "increase"
}
}
}
}
</script>
</head>

<body onload="calculation()">
<table id="table">
<thead>
\(HTML.Composition.header.rawValue)
</thead>
<tfoot>
\(HTML.Composition.footer.rawValue)
</tfoot>
<tbody>
\(HTML.Composition.body.rawValue)
</tbody>
</table>
</body>

</html>
"""
