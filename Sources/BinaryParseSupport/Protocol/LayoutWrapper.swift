//
//  LayoutWrapper.swift
//
//
//  Created by p-x9 on 2023/11/29.
//
//

import Foundation

@dynamicMemberLookup
public protocol LayoutWrapper {
    associatedtype Layout

    var layout: Layout { get set }
}

extension LayoutWrapper {
    public subscript<Value>(dynamicMember keyPath: KeyPath<Layout, Value>) -> Value {
        layout[keyPath: keyPath]
    }
}

extension LayoutWrapper {
    @_spi(Core)
    public static var layoutSize: Int {
        MemoryLayout<Layout>.size
    }

    @_spi(Core)
    public var layoutSize: Int {
        MemoryLayout<Layout>.size
    }
}

extension LayoutWrapper {
    @_spi(Core)
    public static func layoutOffset(of key: PartialKeyPath<Layout>) -> Int {
        MemoryLayout<Layout>.offset(of: key)! // swiftlint:disable:this force_unwrapping
    }

    @_spi(Core)
    public func layoutOffset(of key: PartialKeyPath<Layout>) -> Int {
        MemoryLayout<Layout>.offset(of: key)! // swiftlint:disable:this force_unwrapping
    }
}
