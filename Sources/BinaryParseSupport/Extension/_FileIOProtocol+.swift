//
//  _FileIOProtocol+.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/06
//  
//

import Foundation
import FileIO

extension _FileIOProtocol {
    func readString(
        offset: UInt64
    ) -> String? {
        if let fileHandle = self as? _MemoryMappedFileIOProtocol {
            return String(
                cString: fileHandle.ptr
                    .advanced(by: numericCast(offset))
                    .assumingMemoryBound(to: CChar.self)
            )
        } else {
            return readString(offset: offset, step: 10)
        }
    }

    @inline(__always)
    func readString(
        offset: UInt64,
        size: Int
    ) -> String? {
        if let fileHandle = self as? _MemoryMappedFileIOProtocol {
            return fileHandle.readString(offset: offset)
        } else {
            let data = try! readData(
                offset: numericCast(offset),
                length: size
            )
            return String(cString: data)
        }
    }

    @inline(__always)
    func readString(
        offset: UInt64,
        step: Int
    ) -> String? {
        if let fileHandle = self as? _MemoryMappedFileIOProtocol {
            return fileHandle.readString(offset: offset)
        } else {
            var data = Data()
            var offset = offset
            while true {
                guard let new = try? readData(
                    offset: numericCast(offset),
                    upToCount: step
                ) else { break }
                if new.isEmpty { break }
                data.append(new)
                if new.contains(0) { break }
                offset += UInt64(new.count)
            }

            return String(cString: data)
        }
    }
}

extension _FileIOProtocol {
    @_disfavoredOverload
    @inline(__always)
    func _readString<Encoding: _UnicodeEncoding>(
        offset: Int,
        as encoding: Encoding.Type
    ) -> (String, Int)? {
        if let fileHandle = self as? _MemoryMappedFileIOProtocol {
            return UnsafeRawPointer(fileHandle.ptr)
                .advanced(by: offset)
                .assumingMemoryBound(to: Encoding.CodeUnit.self)
                .readString(
                    as: Encoding.self
                )
        } else {
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
    }
}
