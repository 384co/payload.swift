//
//  PayloadKeyedEncodingContainer.swift
//  SBLib
//
//  Created by Charles Wright on 10/21/24.
//

import Foundation

struct PayloadKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] = []
    let encoder: _PayloadEncoder

    init(encoder: _PayloadEncoder) {
        self.encoder = encoder
    }

    mutating func encodeNil(forKey key: Key) throws {
        // Handle encoding nil
        let nothing: Int? = nil
        try encoder._encode(nothing, as: key.stringValue)
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        // Handle encoding Bool
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        // Handle encoding String
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        // Handle encoding Double
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        // Handle encoding Float
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        // Handle encoding Int
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        // Handle encoding Int8
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        // Handle encoding Int16
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        // Handle encoding Int32
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        // Handle encoding Int64
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        // Handle encoding UInt
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        // Handle encoding UInt8
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        // Handle encoding UInt16
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        // Handle encoding UInt32
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        // Handle encoding UInt64
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        // Handle encoding Encodable types
        try encoder._encode(value, as: key.stringValue)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = PayloadKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return PayloadUnkeyedEncodingContainer(encoder: encoder)
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
}
