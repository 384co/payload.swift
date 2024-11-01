//
//  PayloadSingleValueEncodingContainer.swift
//  SBLib
//
//  Created by Charles Wright on 10/22/24.
//

import Foundation

struct PayloadSingleValueEncodingContainer: SingleValueEncodingContainer {

    var codingPath: [any CodingKey] = []
    var encoder: _PayloadEncoder
    
    init(encoder: _PayloadEncoder) {
        self.encoder = encoder
    }
    
    mutating func encode(_ value: Int) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Double) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Float) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Bool) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: String) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        try _encode(value)
    }
    
    // Conditionally compile for macOS 15+, iOS 18+, etc.
    #if compiler(>=5.9) && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
    mutating func encode(_ value: UInt128) throws {
        try _encode(value)
    }
    
    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
    mutating func encode(_ value: Int128) throws {
        try _encode(value)
    }
    #endif
    
    mutating func encode(_ value: UInt16) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        try _encode(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        try _encode(value)
    }
    
    mutating func encodeNil() throws {
        let nothing: Int? = nil
        try _encode(nothing)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try _encode(value)
    }
    
    // Really encode the value
    // This is the "real" encode function - all of various versions of encode() above are simply thin wrappers around this one.
    // Still, all the work is really done in the Encoder class.  Here we simply ask it to encode our value.
    private mutating func _encode<T>(_ value: T) throws where T: Encodable {
        // FIXME: We need a new way to encode a single value
        throw PayloadEncoderError.invalidCollectionElement("Single value encoding is not implemented")
    }
    
}
