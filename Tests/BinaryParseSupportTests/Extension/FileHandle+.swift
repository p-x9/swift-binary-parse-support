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

extension FileHandle: UnicodeStringReadable {
    public var size: Int {
        try! numericCast(seekToEnd())
    }

    public func _readString<Encoding: _UnicodeEncoding>(
        offset: Int,
        as encoding: Encoding.Type
    ) -> (string: String, numberOfBytes: Int)? {
        var count = 0
        var offset: Int = offset

        var characters: [Encoding.CodeUnit] = []

        while let char = try? read(
            offset: offset,
            as: Encoding.CodeUnit.self
        ), char != 0 {
            characters.append(char)
            count += 1
            offset += MemoryLayout<Encoding.CodeUnit>.size
        }

        characters.append(0)

        return characters.withUnsafeBytes { bufferPtr in
            guard let baseAddress = bufferPtr.baseAddress else {
                return nil
            }
            let string = String(
                decodingCString: baseAddress
                    .assumingMemoryBound(to: Encoding.CodeUnit.self),
                as: Encoding.self
            )
            let length = (count + 1) * MemoryLayout<Encoding.CodeUnit>.size
            return (string, length)
        }
    }

    public func readData(offset: Int, length: Int) throws -> Data {
        try seek(toOffset: numericCast(offset))
        return try read(upToCount: length) ?? .init()
    }

    public func read<T>(offset: Int, as: T.Type) throws -> T {
        let data = try readData(
            offset: offset,
            length: MemoryLayout<T>.size
        )
        return data.withUnsafeBytes {
            $0.load(as: T.self)
        }
    }

    public func readAllData() throws -> Data {
        try readToEnd() ?? .init()
    }
}
