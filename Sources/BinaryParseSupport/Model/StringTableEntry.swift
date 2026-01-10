//
//  StringTableEntry.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/05
//  
//

import Foundation

public struct StringTableEntry: Codable, Equatable, Sendable {
    public let string: String
    ///  Offset from the beginning of the string table
    public let offset: Int
}
