//
//  PayloadEncoder.swift
//  SBLib
//
//  Created by Charles Wright on 10/20/24.
//

import Foundation
import Combine

enum PayloadEncoderError: Error {
    case unsupportedType(String)
    case encodingFailed(String)
    case invalidCollectionElement(String)
}

public class PayloadEncoder: TopLevelEncoder {
    public typealias Output = Data

    public init() {}

    // Magic number, similar to the Unix scheme for indicating and detecting file types
    // Wire-format payloads always start with this 4 byte pattern 0xAABBBBAA which is easy to spot in a hex editor
    static let MAGIC: Data = Data(Array<UInt8>([0xAA, 0xBB, 0xBB, 0xAA]))
    
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let encoder = _PayloadEncoder()
        try value.encode(to: encoder)
        let data = try encoder.finalize()
        return Self.MAGIC + data
    }
}

class _PayloadEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    private var items: [(String, PayloadType, Data)] = []
    
    /*
     * Serialize an Encodable value and add it to our list of serialized items,
     * to be included in our final Data output when finalize() is called.
     */
    func _encode<T: Encodable>(_ value: T?, as name: String) throws {
        if let unwrappedValue = value {
            let type = getPayloadType(unwrappedValue)
            let buffer = try serialize(unwrappedValue)
            items.append( (name, type, buffer) )
        } else {
            let buffer = Data([UInt8](arrayLiteral: 0))
            items.append( (name, .null, buffer) )
        }
    }
    
    func _encode<T: Encodable>(_ value: T?, at index: Int) throws {
        let name = "\(index)"
        let type = getPayloadType(value)
        let buffer = try serialize(value)
        items.append( (name, type, buffer) )
    }

    
    /*
     * Generate our final metadata and concatenate everyting into a single Data object
     */
    func finalize() throws -> Data {
        var data = Data()
        var metadata: [String: PayloadMetadataEntry] = [:]
                
        var keyCount = 0
        var startIndex = 0
                
        for item in items {
            let (name, type, buffer) = item
            data += buffer
            let size = buffer.count
            keyCount += 1
            metadata["\(keyCount)"] = PayloadMetadataEntry(startIndex: startIndex, size: size, type: type, name: name)
            startIndex += size
        }
        
        let metadataBuffer = try JSONEncoder().encode(metadata)
        let metadataSize = metadataBuffer.count
        let metadataSizeBuffer = try serialize(metadataSize)
        
        return metadataSizeBuffer + metadataBuffer + data
        
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = PayloadKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return PayloadUnkeyedEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return PayloadSingleValueEncodingContainer(encoder: self)
    }
        
    // Function to get the type of a value, handling Optionals and specific types
    func getPayloadType<T: Encodable>(_ value: T?) -> PayloadType {
        // Check if value is nil
        guard let unwrappedValue = value else {
            return .null // Return "0" for nil values
        }
        
        // Handle non-nil values
        switch unwrappedValue {
        // Handle signed integers
        case is Int, is Int32, is Int16, is Int8:
            return .integer
            
        case is Int64, is UInt64:
            return .double // Int64 doesn't fit in 4 bytes, so we have to encode it as a Double
        
        // Handle unsigned integers
        case is UInt, is UInt64, is UInt32, is UInt16, is UInt8:
            return .integer  // We encode UInt's just like regular Int's
        
        // Handle floating point numbers
        case is Float, is Double:
            return .double
        
        // Handle specific types
        case is Date:
            return .data
        case is Data:
            return .data
        case is [UInt8]:
            return .uint8Array
        
        // Handle collection types
        case is Array<Any>:
            return .array // Any other kind of Array
        case is Dictionary<AnyHashable, Any>:
            return .map // Any kind of Dictionary
        case is Set<AnyHashable>:
            return .set // Any kind of Set
        
        // Handle other types
        case is String:
            return .string
        case is Bool:
            return .boolean
        
        // Default case: treat it as an object
        default:
            return .object
        }
    }
    
    // The payload encoding scheme encodes maps (ie Dictionary) and sets using arrays
    func serialize<T: Encodable>(_ set: Set<T>) throws -> Data {
        let array = Array(set)
        return try serialize(array)
    }
    
    private struct KeyValuePair<K, V>: Encodable where K: Hashable & Encodable, V: Encodable {
        var key: K
        var value: V

        enum CodingKeys: Int, CodingKey {
            case key = 0
            case value = 1
        }
    }
    
    func serialize<K: Encodable & Hashable, V: Encodable>(_ dict: Dictionary<K,V>) throws -> Data {
        let array: [KeyValuePair<K,V>] = dict.map {
            KeyValuePair(key: $0, value: $1)
        }
        return try serialize(array)
    }
    
    // Most generic version - handles everything else besides sets and maps
    // - Handles atomic types by serializing directly to Data
    // - Handles other Encodable types by recursion
    // - The magic happens because the Swift Array type natively knows how to encode itself by requesting an unkeyed container
    
    func serialize<T: Encodable>(_ input: T) throws -> Data {
        // Special handling for basic types
        switch input {
        // All floating point numbers as Double
        case let number as Float:
            var value = Double(number)
            return withUnsafeBytes(of: &value) { Data($0) }
            
        case let number as Double:
            var value = number
            return withUnsafeBytes(of: &value) { Data($0) }
            
        // Integer types
        case let number as Int:
            var value = Int32(number)
            return withUnsafeBytes(of: &value) { Data($0) }
            
        case let number as Int32:
            var value = number
            return withUnsafeBytes(of: &value) { Data($0) }
            
        case let number as Int16:
            var value = Int32(number)
            return withUnsafeBytes(of: &value) { Data($0) }
            
        case let number as Int8:
            var value = Int32(number)
            return withUnsafeBytes(of: &value) { Data($0) }
            
        case let number as Int64:
            var value = Double(number)
            return withUnsafeBytes(of: &value) { Data($0) }
            
        // Boolean
        case let bool as Bool:
            let value: UInt8 = bool ? 1 : 0
            return Data([value])
            
        // String
        case let string as String:
            guard let data = string.data(using: .utf8) else {
                throw PayloadEncoderError.encodingFailed("Failed to encode string as UTF-8")
            }
            return data
            
        // Date
        case let date as Date:
            var value = date.timeIntervalSince1970
            return withUnsafeBytes(of: &value) { Data($0) }
            
        // Data and [UInt8]
        case let data as Data:
            return data
            
        case let bytes as [UInt8]:
            return Data(bytes)

        // Some other Encodable type
        default:
            // This can't be serialized directly to Data, so we recurse and create a new Encoder object to handle it
            var encoder = _PayloadEncoder()
            try input.encode(to: encoder)
            return try encoder.finalize()
        }
    }
    
}

