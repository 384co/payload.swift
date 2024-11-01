//
//  PayloadMetadataEntry.swift
//  SBLib
//
//  Created by Charles Wright on 10/18/24.
//

struct PayloadMetadataEntry: Codable {
    let startIndex: Int
    let size: Int
    let type: PayloadType
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case startIndex = "s"
        case size = "z"
        case type = "t"
        case name = "n"
    }
}
