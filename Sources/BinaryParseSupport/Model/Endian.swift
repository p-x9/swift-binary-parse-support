//
//  Endian.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/08
//
//

public enum Endian: Sendable {
    case little
    case big
}

extension Endian {
    public static var current: Endian {
        // `CFByteOrderGetCurrent` is unavailable where CoreFoundation
        // is not exposed (e.g. static Linux / musl, Android).
        1.littleEndian == 1 ? .little : .big
    }
}
