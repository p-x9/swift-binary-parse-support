import XCTest
import Foundation
import FileIO
@testable import BinaryParseSupport

final class InFileUnicodeStringsTests: XCTestCase {
    typealias FileHandle = Foundation.FileHandle

    // MARK: - UTF-8 (ASCII)

    func testUTF8SingleString() throws {
        let bytes: [UInt8] = Array("hello".utf8) + [0]

        try withTemporaryFile(
            size: bytes.count,
            contents: Data(bytes)
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF8>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entries = Array(table)

            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries[0].string, "hello")
            XCTAssertEqual(entries[0].offset, 0)
        }
    }

    func testUTF8MultipleStrings() throws {
        let bytes: [UInt8] = [
            "foo", "bar", "baz"
        ].flatMap {
            Array($0.utf8) + [0]
        }

        try withTemporaryFile(
            size: bytes.count,
            contents: Data(bytes)
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF8>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entries = Array(table)

            XCTAssertEqual(entries.map(\.string), ["foo", "bar", "baz"])
            XCTAssertEqual(entries.map(\.offset), [0, 4, 8])
        }
    }

    func testUTF8StringAtOffset() throws {
        let bytes: [UInt8] =
        Array("hello".utf8) + [0] +
        Array("world".utf8) + [0]

        try withTemporaryFile(
            size: bytes.count,
            contents: Data(bytes)
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF8>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entry = table.string(at: 6)

            XCTAssertNotNil(entry)
            XCTAssertEqual(entry?.string, "world")
            XCTAssertEqual(entry?.offset, 6)
        }
    }

    // MARK: - UTF-16 Little Endian

    func testUTF16LE() throws {
        var data = Data()

        data.append(contentsOf: "hello".utf16.flatMap {
            [UInt8($0 & 0xFF), UInt8($0 >> 8)]
        })
        data.append(contentsOf: [0, 0])

        try withTemporaryFile(
            size: data.count,
            contents: data
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF16>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entries = Array(table)

            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries[0].string, "hello")
            XCTAssertEqual(table.string(at: 0)?.string, "hello")
        }
    }

    // MARK: - UTF-16 Big Endian (with BOM)

    func testUTF16BESwappedByBOM() throws {
        var data = Data()

        // BOM (0xFEFF swapped = 0xFFFE)
        data.append(0xFF)
        data.append(0xFE)

        for u in "hi".utf16 {
            data.append(UInt8(u >> 8))
            data.append(UInt8(u & 0xFF))
        }

        data.append(contentsOf: [0, 0])

        try withTemporaryFile(
            size: data.count,
            contents: data
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF16>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entries = Array(table)

            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries[0].string, "hi")
            XCTAssertEqual(table.string(at: 0)?.string, "hi")
        }
    }

    // MARK: - UTF-32 Little Endian

    func testUTF32LE() throws {
        var data = Data()

        for scalar in "A".unicodeScalars {
            let v = scalar.value
            data.append(UInt8(v & 0xFF))
            data.append(UInt8((v >> 8) & 0xFF))
            data.append(UInt8((v >> 16) & 0xFF))
            data.append(UInt8((v >> 24) & 0xFF))
        }

        data.append(contentsOf: [0, 0, 0, 0])

        try withTemporaryFile(
            size: data.count,
            contents: data
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF32>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            let entries = Array(table)

            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries[0].string, "A")
            XCTAssertEqual(table.string(at: 0)?.string, "A")
        }
    }

    // MARK: - Boundary

    func testInvalidOffsetReturnsNil() throws {
        let bytes: [UInt8] = [0]

        try withTemporaryFile(
            size: bytes.count,
            contents: Data(bytes)
        ) { url in
            let file = try FileHandle.open(
                url: url,
                isWritable: false
            )

            let table = UnicodeStrings<UTF8>(
                fileHandle: file,
                offset: 0,
                size: file.size,
                isSwapped: false
            )

            XCTAssertNil(table.string(at: -1))
            XCTAssertNil(table.string(at: file.size))
        }
    }
}
