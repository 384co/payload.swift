//
//  PayloadMetadata.swift
//  SBLib
//
//  Created by Charles Wright on 10/24/24.
//

import Foundation
import os

enum PayloadMetadataError: Error {
    case invalidLength(String)
    case decodingError(String)
}

struct PayloadMetadata: Codable {
    private var entries: [String: PayloadMetadataEntry] = [:]
    private static var logger: os.Logger? = os.Logger(subsystem: "payload", category: "metadata")
    
    subscript(index: String) -> PayloadMetadataEntry? {
        get {
            entries[index]
        }
        
        set(newValue) {
            self.entries[index] = newValue
        }
    }
    
    init(from decoder: any Decoder) throws {
        let dict = try [String: PayloadMetadataEntry](from: decoder)
        Self.logger?.debug("Metadata decoded \(dict.count) entries")
        /*
        for (k,v) in dict {
            Self.logger?.debug("  key = \(k)  name = \(v.name)  startIndex = \(v.startIndex)")
        }
        */
        self.entries = dict
    }
    
    func encode(to encoder: any Encoder) throws {
        try self.entries.encode(to: encoder)
    }
    
    var keys: [String] {
        Array(self.entries.keys)
    }
    
    var count: Int {
        self.entries.count
    }
    
    func getEntry(for name: String) -> PayloadMetadataEntry? {
        self.entries.values.first(where: {$0.name == name})
    }
    
    func getEntry(for index: Int) -> PayloadMetadataEntry? {
        getEntry(for: "\(index)")
    }
    
    static func extract(from data: Data) throws -> (PayloadMetadata, Data) {
        // The first 4 bytes are the metadata length
        // The next bytes are the metadata, encoded as UTF8 JSON
        // The remaining bytes are the actual data
        
        Self.logger?.debug("Extracting metadata and payload from \(data.count) bytes of data")
        
        let lengthData = data.prefix(4)
        guard lengthData.count == 4
        else {
            throw PayloadMetadataError.invalidLength("Metadata length is too short")
        }
        
        guard let metadataLength32: UInt32 = littleEndian(data: lengthData)
        else {
            throw PayloadMetadataError.invalidLength("Could not decode metadata length")
        }
        let metadataLength = Int(metadataLength32)
        Self.logger?.debug("Metadata length is \(metadataLength)")
        guard metadataLength <= data.count
        else {
            throw PayloadMetadataError.invalidLength("Metadata length is longer than data")
        }
        
        let metadataData = data.advanced(by: 4).prefix(metadataLength)
        guard metadataData.count == metadataLength
        else {
            throw PayloadMetadataError.decodingError("Failed to extract metadata bytes")
        }
        let metadataJSON = String(data: metadataData, encoding: .utf8)
        Self.logger?.debug("Metadata JSON is \(metadataJSON ?? "n/a")")
        
        let jsonDecoder = JSONDecoder()
        let metadata = try jsonDecoder.decode(PayloadMetadata.self, from: metadataData)
        
        let rest = data.advanced(by: 4+metadataLength)
        
        return (metadata, rest)
    }
}
