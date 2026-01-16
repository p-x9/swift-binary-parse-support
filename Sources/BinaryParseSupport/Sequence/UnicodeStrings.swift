//
//  UnicodeStrings.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/05
//  
//

import Foundation

public protocol UnicodeStringsSource {
    var size: Int { get }

    func _readString<Encoding: _UnicodeEncoding>(
        offset: Int,
        as encoding: Encoding.Type
    ) -> (string: String, numberOfBytes: Int)?

    func readData(offset: Int, length: Int) throws -> Data
    func read<T>(offset: Int, as: T.Type) throws -> T
    func readAllData() throws -> Data
}

public struct MemoryUnicodeStringsSource: UnicodeStringsSource {
    public let ptr: UnsafeRawPointer
    public let size: Int

    public init(ptr: UnsafeRawPointer, size: Int) {
        self.ptr = ptr
        self.size = size
    }
}

extension MemoryUnicodeStringsSource {
    public func _readString<Encoding: _UnicodeEncoding>(
        offset: Int,
        as encoding: Encoding.Type
    ) -> (string: String, numberOfBytes: Int)? {
        ptr
            .advanced(by: offset)
            .assumingMemoryBound(to: Encoding.CodeUnit.self)
            .readString(as: Encoding.self)
    }

    public func readData(offset: Int, length: Int) throws -> Data {
        .init(bytes: ptr, count: size)
    }

    public func read<T>(offset: Int, as: T.Type) throws -> T {
        ptr
            .advanced(by: offset)
            .assumingMemoryBound(to: T.self)
            .pointee
    }

    public func readAllData() throws -> Data {
        .init(bytes: ptr, count: size)
    }
}

public struct UnicodeStrings<Encoding: _UnicodeEncoding>: StringTable {
    private let source: any UnicodeStringsSource

    /// file offset of string table start
    public let offset: Int

    /// size of string table
    public let size: Int

    public let isSwapped: Bool

    public init(
        source: any UnicodeStringsSource,
        offset: Int,
        size: Int,
        isSwapped: Bool
    ) {
        self.source = source
        self.offset = offset
        self.size = size
        self.isSwapped = isSwapped
    }

    public func makeIterator() -> Iterator {
        .init(source: source, isSwapped: isSwapped)
    }
}

extension UnicodeStrings {
    public var data: Data? {
        try? source.readAllData()
    }
}

extension UnicodeStrings {
    public func string(at offset: Int) -> Element? {
        guard 0 <= offset, offset < source.size else { return nil }

        guard let (_string, length) = source._readString(
            offset: numericCast(offset),
            as: Encoding.self
        ) else {
            return nil
        }
        var string = _string

        let char = try! source.read(
            offset: offset,
            as: Encoding.CodeUnit.self
        )

        if isSwapped || Iterator.shouldSwap(char) {
            handleSwap(
                string: &string,
                at: offset,
                length: length,
                source: source,
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

        private let source: any UnicodeStringsSource
        private let tableSize: Int
        private let isSwapped: Bool

        private var nextOffset: Int

        init(source: any UnicodeStringsSource, isSwapped: Bool) {
            self.source = source
            self.tableSize = source.size
            self.nextOffset = 0
            self.isSwapped = isSwapped
        }

        public mutating func next() -> Element? {
            guard nextOffset < tableSize else { return nil }

            guard let (_string, length) = source._readString(
                offset: nextOffset,
                as: Encoding.self
            ) else { return nil }
            var string = _string

            defer {
                nextOffset += length
            }

            let char = try! source.read(
                offset: nextOffset,
                as: Encoding.CodeUnit.self
            )

            if isSwapped || Self.shouldSwap(char) {
                handleSwap(
                    string: &string,
                    at: nextOffset,
                    length: length,
                    source: source,
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
    source: any UnicodeStringsSource,
    hasBOM: Bool,
    encoding: Encoding.Type
) {
    var data = try! source.readData(
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
