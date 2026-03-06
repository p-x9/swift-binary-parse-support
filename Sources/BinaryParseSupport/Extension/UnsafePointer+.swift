//
//  UnsafePointer+.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/07
//
//

import Foundation

extension UnsafePointer<UInt8> {
    @_spi(Core)
    public func readString() -> (String, Int) {
        let offset = Int(bitPattern: strchr(self, 0)) + 1 - Int(bitPattern: self)
        let string = String(cString: self)

        return (string, offset)
    }
}

extension UnsafePointer<CChar> {
    @_spi(Core)
    public func readString() -> (String, Int) {
        let offset = Int(bitPattern: strchr(self, 0)) + 1 - Int(bitPattern: self)
        let string = String(cString: self)

        return (string, offset)
    }
}

extension UnsafePointer where Pointee: FixedWidthInteger {
    @_spi(Core)
    public func findNullTerminator() -> UnsafePointer<Pointee> {
        findTerminator(0)
    }

    @_spi(Core)
    public func findTerminator(
        _ terminator: Pointee = 0
    ) -> UnsafePointer<Pointee> {
        var ptr = self
        while ptr.pointee != terminator {
            ptr = ptr.advanced(by: 1)
        }
        return ptr
    }

    @_spi(Core)
    public func readString<Encoding: _UnicodeEncoding>(
        as encoding: Encoding.Type,
        terminator: Encoding.CodeUnit = 0
    ) -> (String, Int) where Pointee == Encoding.CodeUnit {
        let terminatorPointer = findTerminator(terminator)
        let length = self.distance(to: terminatorPointer)
        let offset = length * MemoryLayout<Pointee>.size + MemoryLayout<Pointee>.size

        let buffer = UnsafeBufferPointer(start: self, count: length)
        let string = String(decoding: buffer, as: Encoding.self)

        return (string, offset)
    }
}
