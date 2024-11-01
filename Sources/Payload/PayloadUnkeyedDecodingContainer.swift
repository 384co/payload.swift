//
//  PayloadUnkeyedDecodingContainer.swift
//  SBLib
//
//  Created by Charles Wright on 10/17/24.
//

import Foundation
import os

class PayloadUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private var decoder: _PayloadDecoder
    public var codingPath: [CodingKey] = []
    public var currentIndex: Int = 0
    let data: Data
    let metadata: PayloadMetadata
    let startIndex: Int
    
    private var logger: os.Logger? = PayloadDecoder.logger
    
    init(decoder: _PayloadDecoder, data: Data, codingPath: [CodingKey] = []) throws {
        self.decoder = decoder
        self.codingPath = codingPath
        self.startIndex = 0

        
        logger?.debug("Creating new PayloadUnkeyedDecodingContainer for \(data.count) bytes of data")
        
        // Load metadata and remaining data
        (self.metadata, self.data) = try PayloadMetadata.extract(from: data)
        
        logger?.debug("Success decoding metadata")
        logger?.debug("Metadata has \(self.metadata.count) entries")
        for key in self.metadata.keys {
            guard let value = self.metadata[key]
            else {
                logger?.error("Missing metadata entry for key \(key)")
                continue
            }
            logger?.debug("  key = \(key)  name = \(value.name)  type = \(value.type.rawValue)  startIndex = \(value.startIndex)")
        }
        
    }

    public var count: Int? {
        return metadata.count
    }

    public var isAtEnd: Bool {
        return currentIndex >= count!
    }
    
    private func getData(for index: Int) -> Data? {

        guard let entry = self.metadata.getEntry(for: "\(index)")
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

    public func decodeNil() throws -> Bool {
        return false
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        logger?.debug("Bool decode(type: Bool)  index = \(self.currentIndex))")
        
        guard let entry = metadata.getEntry(for: currentIndex),
              let buffer = getData(for: currentIndex)
        else {
            throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(currentIndex)")
        }
        
        let boolValue = try _PayloadDecoder.deserializeBool(buffer, type: entry.type)
        self.currentIndex += 1
        return boolValue
    }

    public func decode(_ type: String.Type) throws -> String {
        //logger?.debug("String decode(type: String)  index = \(self.currentIndex))")

        guard let entry = metadata.getEntry(for: currentIndex),
              let buffer = getData(for: currentIndex)
        else {
            throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(currentIndex)")
        }
        
        let stringValue = try _PayloadDecoder.deserializeString(buffer, type: entry.type)
        self.currentIndex += 1
        return stringValue
    }
    
    public func decodeInteger<T: FixedWidthInteger>() throws -> T {
        logger?.debug("Integer decode(type: \(T.self)  index = \(self.currentIndex))")

        guard let entry = metadata.getEntry(for: currentIndex),
              let buffer = getData(for: currentIndex)
        else {
            throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(currentIndex)")
        }
        
        let integerValue: T = try _PayloadDecoder.deserializeInteger(buffer, type: entry.type)
        self.currentIndex += 1
        return integerValue
    }
    
    public func decodeFloatingPoint<T: BinaryFloatingPoint>() throws -> T {
        logger?.debug("Floating point decode(type: \(T.self)  index = \(self.currentIndex))")

        guard let entry = metadata.getEntry(for: currentIndex),
              let buffer = getData(for: currentIndex)
        else {
            throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(currentIndex)")
        }
        
        let floatValue: T = try _PayloadDecoder.deserializeFloat(buffer, type: entry.type)
        self.currentIndex += 1
        return floatValue
    }

    public func decode(_ type: Double.Type) throws -> Double {
        return try decodeFloatingPoint()
    }

    public func decode(_ type: Float.Type) throws -> Float {
        return try decodeFloatingPoint()
    }

    public func decode(_ type: Int.Type) throws -> Int {
        return try decodeInteger()
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        return try decodeInteger()
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        return try decodeInteger()
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        return try decodeInteger()
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        return try decodeInteger()
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        return try decodeInteger()
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decodeInteger()
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decodeInteger()
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decodeInteger()
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decodeInteger()
    }

    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        logger?.debug("Generic decode(type: \(T.self)  index = \(self.currentIndex))")
        
        guard let entry = metadata.getEntry(for: currentIndex),
        let buffer = getData(for: currentIndex)
        else {
        throw PayloadDecoderError.parsingError("Failed to load data and metadata for \(currentIndex)")
        }        
         
        switch entry.type {
        case .array, .set, .object, .map:
        logger?.debug("Recursing to decode \(T.self)")
            let decoder = _PayloadDecoder(data: buffer)
            let t = try T(from: decoder)
            self.currentIndex += 1
            return t
         
        default:
            logger?.error("Can't decode Swift type \(T.self) from serialized type \(entry.type.rawValue)")
            throw PayloadDecoderError.unsupportedType("Can't decode Swift type \(T.self) from serialized type \(entry.type.rawValue)")
        }
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        fatalError("Nested containers are not supported")
    }

    public func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Nested containers are not supported")
    }

    public func superDecoder() throws -> Decoder {
        fatalError("Super decoder is not supported")
    }

}
