//
//  UnicodeStrings.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/05
//  
//

import Foundation
import FileIO

public struct UnicodeStrings<
    File: _FileIOProtocol,
    Encoding: _UnicodeEncoding
>: StringTable {
    private let fileHandle: File

    /// file offset of string table start
    public let offset: Int

    /// size of string table
    public let size: Int

    public let isSwapped: Bool

    init(
        fileHandle: File,
        offset: Int,
        size: Int,
        isSwapped: Bool
    ) {
        self.fileHandle = fileHandle
        self.offset = offset
        self.size = size
        self.isSwapped = isSwapped
    }

    public func makeIterator() -> Iterator {
        .init(fileHandle: fileHandle, isSwapped: isSwapped)
    }
}

extension UnicodeStrings {
    public var data: Data? {
        try? fileHandle.readAllData()
    }
}

extension UnicodeStrings {
    public func string(at offset: Int) -> Element? {
        guard 0 <= offset, offset < fileHandle.size else { return nil }

        guard let (_string, length) = fileHandle._readString(
            offset: numericCast(offset),
            as: Encoding.self
        ) else {
            return nil
        }
        var string = _string

        let char = try! fileHandle.read(
            offset: offset,
            as: Encoding.CodeUnit.self
        )

        if isSwapped || Iterator.shouldSwap(char) {
            handleSwap(
                string: &string,
                at: offset,
                length: length,
                fileHandle: fileHandle,
                hasBOM: Iterator.shouldSwap(char),
                encoding: Encoding.self
            )
        }
        return .init(string: string, offset: offset)
    }
}

extension UnicodeStrings {
    public struct Iterator: IteratorProtocol {
        public typealias Element = StringTableEntry

        private let fileHandle: File
        private let tableSize: Int
        private let isSwapped: Bool

        private var nextOffset: Int

        init(fileHandle: File, isSwapped: Bool) {
            self.fileHandle = fileHandle
            self.tableSize = fileHandle.size
            self.nextOffset = 0
            self.isSwapped = isSwapped
        }

        public mutating func next() -> Element? {
            guard nextOffset < tableSize else { return nil }

            guard let (_string, length) = fileHandle._readString(
                offset: nextOffset,
                as: Encoding.self
            ) else { return nil }
            var string = _string

            defer {
                nextOffset += length
            }

            let char = try! fileHandle.read(
                offset: nextOffset,
                as: Encoding.CodeUnit.self
            )

            if isSwapped || Self.shouldSwap(char) {
                handleSwap(
                    string: &string,
                    at: nextOffset,
                    length: length,
                    fileHandle: fileHandle,
                    hasBOM: Self.shouldSwap(char),
                    encoding: Encoding.self
                )
            }

            return .init(
                string: string,
                offset: nextOffset
            )
        }
    }
}

extension UnicodeStrings.Iterator {
    // https://github.com/swiftlang/swift-corelibs-foundation/blob/4a9694d396b34fb198f4c6dd865702f7dc0b0dcf/Sources/Foundation/NSString.swift#L1390
    static func shouldSwap(
        _ char: Encoding.CodeUnit
    ) -> Bool {
        let size = MemoryLayout<Encoding.CodeUnit>.size
        var char = char
        if Endian.current == .little {
            char = char.byteSwapped
        }
        switch size {
        case 1:
            return false
        case 2:
            return char == 0xFFFE /* ZERO WIDTH NO-BREAK SPACE */
        case 4:
            return char == UInt32(0xFFFE0000) // avoid overflows in 32bit env
        default:
            return false
        }
    }
}

fileprivate func handleSwap<Encoding: _UnicodeEncoding>(
    string: inout String,
    at offset: Int,
    length: Int,
    fileHandle: some _FileIOProtocol,
    hasBOM: Bool,
    encoding: Encoding.Type
) {
    var data = try! fileHandle.readData(
        offset: offset,
        length: length
    )

    // strip BOM
    if hasBOM {
        data.removeFirst(MemoryLayout<Encoding.CodeUnit>.size)
    }

    data = data.byteSwapped(Encoding.CodeUnit.self)

    string = data.withUnsafeBytes {
        let baseAddress = $0.baseAddress!
            .assumingMemoryBound(to: Encoding.CodeUnit.self)
        return .init(
            decodingCString: baseAddress,
            as: Encoding.self
        )
    }
}
