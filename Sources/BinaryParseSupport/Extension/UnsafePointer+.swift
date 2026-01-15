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
        var ptr = self
        while ptr.pointee != 0 {
            ptr = ptr.advanced(by: 1)
        }
        return ptr
    }

    @_spi(Core)
    public func readString<Encoding: _UnicodeEncoding>(
        as encoding: Encoding.Type
    ) -> (String, Int) where Pointee == Encoding.CodeUnit {
        let nullTerminator = findNullTerminator()
        let offset = Int(bitPattern: nullTerminator) + MemoryLayout<Pointee>.size - Int(bitPattern: self)
        let string = String(decodingCString: self, as: Encoding.self)

        return (string, offset)
    }
}

