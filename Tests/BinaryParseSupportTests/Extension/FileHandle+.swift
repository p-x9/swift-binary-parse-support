//
//  FileHandle+.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/15
//  
//

import Foundation
import BinaryParseSupport

extension FileHandle {
    static func open(url: URL, isWritable: Bool) throws -> FileHandle {
        if isWritable {
            return try .init(forWritingTo: url)
        } else {
            return try .init(forReadingFrom: url)
        }
    }
}
