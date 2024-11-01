// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// MARK: big and little endian

public func bigEndian<T: UnsignedInteger>(data: Data) -> T? {
    guard data.count == MemoryLayout<T>.size
    else {
        return nil
    }
    
    let bytes = [UInt8](data)
    let zero: T = 0
    return bytes.reduce(zero) {
        $0 << 8 + T($1)
    }
}

public func littleEndian<T: UnsignedInteger>(data: Data) -> T? {
    guard data.count == MemoryLayout<T>.size
    else {
        return nil
    }
    
    let bytes = [UInt8](data).reversed()
    let zero: T = 0
    return bytes.reduce(zero) {
        $0 << 8 + T($1)
    }
}
