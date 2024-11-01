//
//  PayloadDecoder.swift
//  SBLib
//
//  Created by Charles Wright on 10/17/24.
//

import Foundation
import Combine
import os

public enum PayloadDecoderError: Error {
    case unsupportedType(String)
    case parsingError(String)
    case metadataError(String)
}

public class PayloadDecoder: TopLevelDecoder {
    public typealias Input = Data
    
    public static var logger: os.Logger? = os.Logger(subsystem: "payload", category: "decoder")

    // Magic number, similar to the Unix scheme for indicating and detecting file types
    // Wire-format payloads always start with this 4 byte pattern 0xAABBBBAA which is easy to spot in a hex editor
    static let MAGIC: Data = Data(Array<UInt8>([0xAA, 0xBB, 0xBB, 0xAA]))

    // The top-level payload structure for v3 of the encoder
    struct V3TopLevelWrapper<T: Decodable>: Decodable {
        var isVersion3: Bool
        var payload: T
        
        var logger: os.Logger? = PayloadDecoder.logger
        
        enum CodingKeys: String, CodingKey {
            case isVersion3 = "ver003"
            case payload
        }
        
        init(from decoder: any Decoder) throws {
            logger?.debug("Decoding wrapper")
            let container: KeyedDecodingContainer<PayloadDecoder.V3TopLevelWrapper<T>.CodingKeys> = try decoder.container(keyedBy: PayloadDecoder.V3TopLevelWrapper<T>.CodingKeys.self)
            logger?.debug("Wraper decoding isVersion3")
            self.isVersion3 = try container.decode(Bool.self, forKey: .isVersion3)
            logger?.debug("Wrapper decoding payload")
            self.payload = try container.decode(T.self, forKey: .payload)
        }
    }
    
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        Self.logger?.debug("PayloadDecoder: decoding \(type) from \(data.count) bytes of data")
        
        let magic = data.prefix(4)
        guard magic.count == 4,
              magic == Self.MAGIC
        else {
            throw PayloadDecoderError.parsingError("Invalid data - Not an encoded payload")
        }
        
        // Decode the top-level "wrapper" structure and sanity check it
        Self.logger?.debug("Decoding top-level wrapper")
        let wrapperDecoder = _PayloadDecoder(data: data.advanced(by: Self.MAGIC.count))
        let wrapper = try V3TopLevelWrapper<T>(from: wrapperDecoder)
        guard wrapper.isVersion3
        else {
            throw PayloadDecoderError.metadataError("Unsupported version")
        }
        Self.logger?.debug("Success decoding top-level wrapper")
        
        // If the sanity check checks out, then our result is the payload of the top-level wrapper object
        return wrapper.payload
    }
}

class _PayloadDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var data: Data
    
    public static var logger: os.Logger? = PayloadDecoder.logger
    
    init(data: Data) {
        Self.logger?.debug("Creating new _PayloadDecoder for \(data.count) bytes of data")
        self.data = data
    }
    
    // MARK: Decoder compliance
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = try PayloadKeyedDecodingContainer(decoder: self, data: data, keyedBy: type, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try PayloadUnkeyedDecodingContainer(decoder: self, data: data, codingPath: codingPath)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("Single value decoding is not supported")
    }

    
    // MARK: Low-level loader functions
    // These extract the most basic Payload types (integer, number, bytes) from raw Data
    // These are called by the deserialization functions (below) to produce a wider variety of Swift types
    
    // Int32 is the "base" case for all Integer types
    static func loadInt32(from buffer: Data) throws -> Int32 {
        Self.logger?.debug("Loading Int32 from \(buffer.count) bytes of data")
        guard buffer.count == MemoryLayout<Int32>.size
        else {
            throw PayloadDecoderError.parsingError("Loading Int32 requires \(MemoryLayout<Int32>.size) bytes")
        }
        
        return buffer.withUnsafeBytes { $0.load(as: Int32.self) }
    }
    
    // Double is the "base" case for all floating point types,
    // and also for integer types that require more than 32 bits
    static func loadDouble(from buffer: Data) throws -> Double {
        Self.logger?.debug("Loading Double from \(buffer.count) bytes of data")
        guard buffer.count == MemoryLayout<Double>.size
        else {
            throw PayloadDecoderError.parsingError("Loading Double requires \(MemoryLayout<Double>.size) bytes")
        }
        
        return buffer.withUnsafeBytes { $0.load(as: Double.self) }
    }
    
    static func loadString(from buffer: Data) throws -> String {
        Self.logger?.debug("Loading String from \(buffer.count) bytes of data")
        guard let string = String(data: buffer, encoding: .utf8)
        else {
            throw PayloadDecoderError.parsingError("Failed to load UTF8 String")
        }
        return string
    }
    
    // MARK: Deserialization functions
    // * For atomic types, we can simply call the loader functions above
    // * For higher-order types, we need to create another instance of this class,
    //   which will then:
    //   1. Provide a keyed or unkeyed container
    //   2. Be called on to deserialize more primitive types inside that container
    
    // Deserialize any built-in integer type from serialized integers via Int32 for 'i' or from serialized numbers via Double for 'n'
    static func deserializeInteger<T: FixedWidthInteger>(_ buffer: Data, type: PayloadType) throws -> T {
        Self.logger?.debug("Integer deserialize()")

        switch type {
        case .integer:
            // Easy case.  It's serialized as an integer with fewer bits.
            // Just load it.
            let i32: Int32 = try loadInt32(from: buffer)
            guard i32 <= T.max,
                  T.min <= i32
            else {
                throw PayloadDecoderError.parsingError("Loaded value does not fit in \(T.self)")

            }
            return T(i32)
            
        case .double:
            // Harder case. Maybe the number has too many bits for Int32, so it was serialized as a Double (aka Float64).
            // Load it as a Double and check that it *probably* was an Integer before being serialized.  Fortunately Swift provides the .rounded() function that does this for us.
            let d: Double = try loadDouble(from: buffer)
            guard Double(Int64.min) <= d,
                  d <= Double(Int64.max)
            else {
                throw PayloadDecoderError.parsingError("Loaded number is out of bounds for \(T.self)")
            }
            guard d == d.rounded()
            else {
                throw PayloadDecoderError.parsingError("Loaded number has a fractional part")
            }
            return T(d)
            
        default:
            throw PayloadDecoderError.unsupportedType("Cannot deserialize \(T.self) from \(type)")
        }
    }
    
    // Deserialize floating point types by loading from either Int32 or Double, depending on how the number was encoded
    static func deserializeFloat<T: BinaryFloatingPoint>(_ buffer: Data, type: PayloadType) throws -> T {
        Self.logger?.debug("Floating point deserialize()")

        switch type {
        case .integer:
            let i32 = try loadInt32(from: buffer)
            return T(i32)
            
        case .double:
            let d = try loadDouble(from: buffer)
            return T(d)
            
        default:
            throw PayloadDecoderError.unsupportedType("Cannot deserialize \(T.self) from \(type)")
        }
    }
    
    // Deserialize Date by loading a Double which is also conveniently the underlying type in Swift
    static func deserializeDate(_ buffer: Data, type: PayloadType) throws -> Date {
        Self.logger?.debug("Date deserialize()")

        guard type == .double
        else {
            throw PayloadDecoderError.unsupportedType("Cannot deserialize Date from \(type)")
        }
        let msecSince1970 = try loadDouble(from: buffer)
        let secondsSince1970 = msecSince1970 / 1000
        return Date(timeIntervalSince1970: secondsSince1970)
    }
    
    // Deserialize a Bool as a UInt8 array of length one
    static func deserializeBool(_ buffer: Data, type: PayloadType) throws -> Bool {
        Self.logger?.debug("Bool deserialize()")

        guard type == .boolean
        else {
            throw PayloadDecoderError.unsupportedType("Cannot deserialize Bool from \(type)")
        }
        guard buffer.count == 1,
              let byte = buffer.first
        else {
            throw PayloadDecoderError.parsingError("Failed to deserialize Bool as [UInt8]")
        }
        return byte != 0
    }
    
    // Deserialize a UInt8 array by converting the data directly
    static func deserializeUInt8(_ buffer: Data, type: PayloadType) throws -> [UInt8] {
        Self.logger?.debug("[UInt8] deserialize()")
        
        switch type {
        case .data, .uint8Array:
            let array = Array<UInt8>(buffer)
            return array

        case .array:
            let decoder = _PayloadDecoder(data: buffer)
            return try [UInt8](from: decoder)

        default:
            throw PayloadDecoderError.unsupportedType("Cannot deserialize [UInt8] from \(type)")
        }
    }
    
    // Deserialize a String by simply calling the load function
    static func deserializeString(_ buffer: Data, type: PayloadType) throws -> String {
        guard type == .string
        else {
            throw PayloadDecoderError.unsupportedType("Cannot deserialize String from \(type)")
        }
        return try loadString(from: buffer)
    }
    
    // Deserialize an array by creating a new Decoder instance,
    // which will extract metadata and provide an unkeyed decoding container
    static func deserializeArray<T>(
        _ buffer: Data,
        type: PayloadType
    ) throws -> [T]
      where T: Decodable
    {
        Self.logger?.debug("Array deserialize()")
        
        guard type == .set || type == .array
        else {
            throw PayloadDecoderError.unsupportedType(type.rawValue)
        }
        
        let decoder = _PayloadDecoder(data: buffer)
        let array = try [T](from: decoder)
        return array
    }

    // Deserialize a set by first deserializing an array,
    // and then taking the Set of values in the array
    static func deserializeSet<T>(
        _ buffer: Data,
        type: PayloadType
    ) throws -> Set<T>
      where T: Hashable & Decodable
    {
        Self.logger?.debug("Set deserialize()")
        
        guard type == .set || type == .array
        else {
            throw PayloadDecoderError.unsupportedType(type.rawValue)
        }
        
        let decoder = _PayloadDecoder(data: buffer)
        let array = try [T](from: decoder)
        return Set(array)
    }
    
    private struct KeyValuePair<K, V>: Decodable where K: Hashable & Decodable, V: Decodable {
        var key: K
        var value: V

        enum CodingKeys: Int, CodingKey {
            case key = 0
            case value = 1
        }
    }

    // Deserialize a dictionary as an array of (key,value) pairs
    static func deserialize<K, V>(
        _ buffer: Data,
        type: PayloadType
    ) throws -> [K:V]
      where K: Decodable & Hashable, V: Decodable
    {
        Self.logger?.debug("Dictionary deserialize()")
        
        switch type {
        case .map:
            let decoder = _PayloadDecoder(data: buffer)
            let pairs = try [KeyValuePair<K, V>](from: decoder)
            let dictionary = Dictionary<K,V>(uniqueKeysWithValues: pairs.map { ($0.key, $0.value) })
            return dictionary

        default:
            throw PayloadDecoderError.unsupportedType(type.rawValue)
        }
    }
    
    static func deserialize<T>(_ buffer: Data, type: PayloadType) throws -> T where T: Decodable {
        Self.logger?.debug("Generic deserialize: Loading \(T.self) from \(buffer.count) bytes of data as \(type.rawValue)")
        
        guard type == .object
        else {
            //Self.logger?.error("Cannot deserialize \(T.self) from \(type)")
            throw PayloadDecoderError.unsupportedType("Cannot deserialize \(T.self) from \(type)")
        }
        
        let decoder = _PayloadDecoder(data: buffer)
        return try T(from: decoder)
    }
}



