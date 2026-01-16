# BinaryParseSupport

A Swift library providing utilities and protocols for parsing binary

<!-- # Badges -->

[![Github issues](https://img.shields.io/github/issues/p-x9/swift-binary-parse-support)](https://github.com/p-x9/swift-binary-parse-support/issues)
[![Github forks](https://img.shields.io/github/forks/p-x9/swift-binary-parse-support)](https://github.com/p-x9/swift-binary-parse-support/network/members)
[![Github stars](https://img.shields.io/github/stars/p-x9/swift-binary-parse-support)](https://github.com/p-x9/swift-binary-parse-support/stargazers)
[![Github top language](https://img.shields.io/github/languages/top/p-x9/swift-binary-parse-support)](https://github.com/p-x9/swift-binary-parse-support/)

## Overview

**BinaryParseSupport** is a Swift library providing utilities and protocols for parsing binary data, with a focus on string tables, memory sequences, and endian-aware operations.
It is designed to support efficient and safe binary parsing for file formats and data structures.

## Features

- **LayoutWrapper:**
    Protocol for types that wrap a layout struct, providing convenient access to its properties and memory layout information

- **Endian Utilities:**
  Handle endianness using the `Endian` model.

- **Bit Flags:**
  Protocol for working with bit flags and option sets, using a strongly-typed Bit enumeration for type-safe flag access and iteration.

- **Memory and Data Sequences:**
  Iterate over binary data as typed sequences using `MemorySequence` and `DataSequence`.

- **String Table Parsing:**
  Parse and access string tables in various Unicode encodings (UTF-8, UTF-16, UTF-32), with support for BOM and endianness.

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(
    url: "https://github.com/p-x9/swift-binary-parse-support.git",
    from: "0.2.0"
)
```

Then add `"BinaryParseSupport"` to your target dependencies.

## Usage

### LayoutWrapper Protocol

`LayoutWrapper` is a protocol for types that wrap a layout struct, providing convenient access to its properties and memory layout information.
It uses Swift's `@dynamicMemberLookup` to allow direct access to the wrapped layout's properties, and provides static and instance properties for layout size and offset calculations.

#### Example

```swift
struct MyLayout {
  var field1: UInt32
  var field2: UInt16
}

struct Wrapper: LayoutWrapper {
  var layout: MyLayout
}

let wrapper = Wrapper(layout: MyLayout(field1: 10, field2: 20))
print(wrapper.field1) // Accesses layout.field1 directly
print(Wrapper.layoutSize) // Size of MyLayout
print(Wrapper.layoutOffset(of: \.field2)) // Offset of field2 in MyLayout
```

This protocol is useful for binary parsing and memory-mapped structures, enabling ergonomic and type-safe access to layout fields and their offsets.

### BitFlags Protocol

`BitFlags` is a protocol that combines `OptionSet` and `Sendable`, and introduces a strongly-typed `Bit` enumeration. This enables type-safe access to individual flags and convenient iteration over all possible bits.

The `bits` property returns all enabled bits in the set.

#### Example

```swift
public struct VMProtection: BitFlags {
    public typealias RawValue = vm_prot_t

    public let rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension VMProtection {
    /// VM_PROT_NONE
    public static let none = VMProtection([])
    /// VM_PROT_READ
    public static let read = VMProtection(
        rawValue: Bit.read.rawValue
    )
    /// VM_PROT_WRITE
    public static let write = VMProtection(
        rawValue: Bit.write.rawValue
    )
    /// VM_PROT_EXECUTE
    public static let execute = VMProtection(
        rawValue: Bit.execute.rawValue
    )
}
```

### MemorySequence / DataSequence

`MemorySequence` / `DataSequence` is a structure for parsing an array of a specific type that is arranged consecutively.

Complies with `RandomAccessCollection`.

#### Example

```swift
let pointer: UnsafePointer<MyStruct> = ...
let sequence = MemorySequence(basePointer: pointer, numberOfElements: count)
for element in sequence {
    // Process element
}

let element: MyStruct = sequence[0]
```

### String Table

`UnicodeStrings` is a generic string table abstraction for binary formats that store
Unicode strings as null-terminated sequences and reference them by byte offsets.

Supports UTF-8/UTF-16/UTF-32, and handles BOM correctly.

#### Example

```swift
let file: FileHandle = ... // Opened file handle
let table = UnicodeStrings<UTF8>(
    source: file,
    offset: 0,
    size: file.size,
    isSwapped: false
)

// Scan the table
for entry in table {
    print(entry.offset, entry.string)
}

// Retrieve a string starting from a specific offset
if let entry = table.string(at: 0) {
    print(entry.string)
}
```

## License

BinaryParseSupport is released under the MIT License. See [LICENSE](./LICENSE)
