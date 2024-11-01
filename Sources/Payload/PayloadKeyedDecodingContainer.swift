//
//  PayloadKeyedDecodingContainer.swift
//  SBLib
//
//  Created by Charles Wright on 10/17/24.
//

import Foundation
import Combine
import os

struct PayloadKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    private var decoder: _PayloadDecoder
    public var codingPath: [CodingKey] = []
    let data: Data
    let metadata: PayloadMetadata
    let startIndex: Int
    private var logger: os.Logger? = PayloadDecoder.logger
    
    init(decoder: _PayloadDecoder, data: Data, keyedBy type: Key.Type, codingPath: [CodingKey] = []) throws {
        
        logger?.debug("Creating new PayloadKeyedDecodingContainer")
        
        self.decoder = decoder
        self.codingPath = codingPath
        self.startIndex = 0
        // We don't need to do anything with `type` - it's just here so the Swift compiler knows how to instantiate the struct
                
        // Extract metadata and remaining data
        (self.metadata, self.data) = try PayloadMetadata.extract(from: data)
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                           forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard let nestedData = getData(for: key)
        else {
            throw PayloadDecoderError.parsingError("Failed to get data for key \(key)")
        }
        
        let container = try PayloadKeyedDecodingContainer<NestedKey>(decoder: self.decoder, data: nestedData, keyedBy: type, codingPath: self.codingPath + [key])
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        guard let nestedData = getData(for: key)
        else {
            throw PayloadDecoderError.parsingError("Failed to get data for key \(key)")
        }
        
        let container = try PayloadUnkeyedDecodingContainer(decoder: self.decoder, data: nestedData, codingPath: self.codingPath + [key])
        return container
    }
    
    public func superDecoder() throws -> any Decoder {
        self.decoder
    }
    
    public func superDecoder(forKey key: Key) throws -> any Decoder {
        guard let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to get data for key \(key)")
        }
        
        return _PayloadDecoder(data: buffer)
    }
    
    private func getData(for key: Key) -> Data? {
        guard let entry = self.metadata.getEntry(for: key.stringValue)
        else {
            return nil
        }
        let start = entry.startIndex
        let end = start + entry.size
        
        guard 0 <= start,
              start < end,
              end <= data.count
        else {
            return nil
        }
        
        return data[start..<end]
    }

    public var allKeys: [Key] {
        return metadata.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return metadata[key.stringValue] != nil
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        return !self.contains(key)
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        logger?.debug("Bool decode(type: Bool, forKey: \(key.stringValue))")
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(key)")
        }
        return try _PayloadDecoder.deserializeBool(buffer, type: entry.type)
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        return try _PayloadDecoder.deserializeString(buffer, type: entry.type)
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try decodeFloatingPoint(forKey: key)
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        return try decodeFloatingPoint(forKey: key)
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return try decodeInteger(forKey: key)
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return try decodeInteger(forKey: key)
    }

    private func decodeInteger<T: FixedWidthInteger>(forKey key: Key) throws -> T {
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        return try _PayloadDecoder.deserializeInteger(buffer, type: entry.type)
    }
    
    private func decodeFloatingPoint<T: BinaryFloatingPoint>(forKey key: Key) throws -> T {
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        return try _PayloadDecoder.deserializeFloat(buffer, type: entry.type)
    }

    
    public func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        logger?.debug("Generic keyed decode<T>(type: \(type), forKey: \(key.stringValue))")
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        switch entry.type {
        case .array, .set, .map, .object:
            //logger?.debug("  Type DS = \(DS.self) is a DecodableSequence.Type")
            //return try decodeSequence(DS.self, forKey: key) as! T
            logger?.debug("Recursing to decode sequence of type \(T.self)")
            let decoder = _PayloadDecoder(data: buffer)
            return try T(from: decoder)
            
        default:
            logger?.debug("Can't decode Swift type \(T.self) from payload type \(entry.type.rawValue)")
            throw PayloadDecoderError.unsupportedType("Unsupported type \(T.self)")
        }
    }

}
