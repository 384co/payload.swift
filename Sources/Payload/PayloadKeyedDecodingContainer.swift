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
    
    /*
    public func decodeArray<T>(of type: T.Type, forKey key: Key) throws -> [T] where T: Decodable {
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        let decoder = _PayloadDecoder(data: buffer)
        return try [T](from: decoder)
    }
    */
    
    typealias DecodableCollection = Decodable & Collection
    
    public func decodeCollection<DC>(_ type: DC.Type, forKey key: Key) throws -> DC where DC: DecodableCollection {
        logger?.debug("Collection decode<T>(type: \(type), forKey: \(key.stringValue))")
        
        let E = DC.Element.self
        //let array: Array<DC.Element.Type> = decodeArray(of: DC.Element.Type, forKey: key)
        throw PayloadDecoderError.parsingError("Not implemented")
    }
        
    typealias DecodableSequence = Decodable & Sequence

    public func decodeSequence<DS>(_ type: DS.Type, forKey key: Key) throws -> DS where DS: DecodableSequence, DS.Element: Decodable {
        logger?.debug("Sequence decode<T>(type: \(type), forKey: \(key.stringValue))")
        logger?.debug("  Element type E = \(DS.Element.Type.self)")
        
        let array = try decodeArray([DS.Element].self, forKey: key)
        logger?.debug("  Decoded \(array.count) elements in an array")

        throw PayloadDecoderError.unsupportedType("Not implemented")
    }

    
    public func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        logger?.debug("Generic decode<T>(type: \(type), forKey: \(key.stringValue))")
        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        /*
        if T.self is any Collection.Type
        {
            logger?.debug("  Type T = \(T.self) is a Collection.")
        } else {
            logger?.debug("  Not a Collection")
        }
        
        if let C = T.self as? any Collection.Type {
            logger?.debug("  Type C = \(C.self) is a Collection.Type")
        }
        
        if T.self is any DecodableCollection.Type {
            logger?.debug("  Type T is a DecodableCollection")
            //return try decodeCollection(type, forKey: key)
        }
        
        if let DC = T.self as? any DecodableCollection.Type {
            logger?.debug("  Type DC = \(DC.self) is a DecodableCollection.Type")
            //return try decodeCollection(DC.self, forKey: key) as! T
        }
        */
        
        if let DS = T.self as? any DecodableSequence.Type {
            //logger?.debug("  Type DS = \(DS.self) is a DecodableSequence.Type")
            //return try decodeSequence(DS.self, forKey: key) as! T
            logger?.debug("Recursing to decode sequence of type \(T.self)")
            let decoder = _PayloadDecoder(data: buffer)
            return try T(from: decoder)
        }
        
        logger?.debug("Unsupported type \(T.self)")
        throw PayloadDecoderError.unsupportedType("Unsupported type \(T.self)")
    }
    
    // Function to convert a sequence to a dictionary
    func toDictionary<T: Sequence>(sequence: T) -> [String: T.Element] where T: DecodableSequence, T.Element: Decodable {
        var dict = [String: T.Element]()
        var index = 0
        for element in sequence {
            dict["\(index)"] = element
            index += 1
        }
        return dict
    }
    
    func toArray<T>(sequence: T) -> [T.Element] where T: DecodableSequence, T.Element: Decodable {
        Array(sequence)
    }
    
    func decodeArray<T>(_ type: T.Type, forKey key: Key) throws -> [T.Element] where T: DecodableSequence, T.Element: Decodable {
        logger?.debug("Array decode<T>(type: \(type), forKey: \(key.stringValue))  T.Element = \(T.Element.Type.self)")

        guard let entry = metadata.getEntry(for: key.stringValue),
              let buffer = getData(for: key)
        else {
            throw PayloadDecoderError.metadataError("Failed to load data and metadata for \(key)")
        }
        
        var container = try nestedUnkeyedContainer(forKey: key)
        let array: [T.Element] = try container.decode([T.Element].self)
        return array
    }

}
