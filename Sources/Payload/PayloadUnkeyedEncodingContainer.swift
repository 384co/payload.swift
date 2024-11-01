//
//  PayloadUnkeyedEncodingContainer.swift
//  SBLib
//
//  Created by Charles Wright on 10/21/24.
//

import Foundation

struct PayloadUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey] = []
    let encoder: _PayloadEncoder
    var count: Int = 0

    init(encoder: _PayloadEncoder) {
        self.encoder = encoder
    }

    mutating func encodeNil() throws {
        let nothing: Int? = nil
        try _encode(nothing)
    }

    mutating func encode(_ value: Bool) throws {
        try _encode(value)
    }

    mutating func encode(_ value: String) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Double) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Float) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Int) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Int8) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Int16) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Int32) throws {
        try _encode(value)
    }

    mutating func encode(_ value: Int64) throws {
        try _encode(value)
    }

    mutating func encode(_ value: UInt) throws {
        try _encode(value)
    }

    mutating func encode(_ value: UInt8) throws {
        try _encode(value)
    }

    mutating func encode(_ value: UInt16) throws {
        try _encode(value)
    }

    mutating func encode(_ value: UInt32) throws {
        try _encode(value)
    }

    mutating func encode(_ value: UInt64) throws {
        try _encode(value)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        try _encode(value)
    }
    
    // This is the "real" encode function.
    // All of the above versions of encode() are just wrappers around this one.
    // Still, the real functionality is in the Encoder type.  All we have to do is ask it to encode the next item in the list, and increment our count.
    private mutating func _encode<T>(_ value: T) throws where T: Encodable {
        try encoder._encode(value, at: count)
        count += 1
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = PayloadKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return PayloadUnkeyedEncodingContainer(encoder: encoder)
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }
}
