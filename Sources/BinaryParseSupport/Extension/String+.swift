//
//  String+.swift
//  swift-binary-parse-support
//
//  Created by p-x9 on 2026/01/07
//  
//

import Foundation

extension String {
    public init?(cString data: Data) {
        guard !data.isEmpty else { return nil }
        let string: String? = data.withUnsafeBytes {
            guard let baseAddress = $0.baseAddress else { return nil }
            let ptr = baseAddress.assumingMemoryBound(to: CChar.self)
            return String(cString: ptr)
        }
        guard let string else {
            return nil
        }
        self = string
    }
}
