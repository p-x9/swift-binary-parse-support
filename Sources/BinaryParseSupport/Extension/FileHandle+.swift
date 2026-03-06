//
//  FileHandle+.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/18
//
//

import Foundation

extension FileHandle: UnicodeStringsSource {
    @_implements(UnicodeStringsSource, size)
    public var _unicodeStringsSourceSize: Int {
        let current = offsetInFile
        let size = seekToEndOfFile()
        seek(toFileOffset: current)
        return numericCast(size)
    }

    public func _readString<Encoding: _UnicodeEncoding>(
        offset: Int,
        as encoding: Encoding.Type,
        terminator: Encoding.CodeUnit
    ) -> (string: String, numberOfBytes: Int)? {
        var offset: Int = offset

        var characters: [Encoding.CodeUnit] = []

        while let char = try? read(
            offset: offset,
            as: Encoding.CodeUnit.self
        ), char != terminator {
            characters.append(char)
            offset += MemoryLayout<Encoding.CodeUnit>.size
        }
        let string = String(decoding: characters, as: Encoding.self)
        let length = (characters.count + 1) * MemoryLayout<Encoding.CodeUnit>.size
        return (string, length)
    }

    public func readData(offset: Int, length: Int) throws -> Data {
        seek(toFileOffset: numericCast(offset))
        return readData(
            ofLength: length
        )
    }

    public func read<T>(offset: Int, as: T.Type) throws -> T {
        seek(toFileOffset: numericCast(offset))
        let data = readData(
            ofLength: MemoryLayout<T>.size
        )
        precondition(
            data.count >= MemoryLayout<T>.size,
            "Invalid Data Size"
        )
        return data.withUnsafeBytes {
            $0.load(as: T.self)
        }
    }

    public func readAllData() throws -> Data {
        try readData(offset: 0, length: size)
    }
}
