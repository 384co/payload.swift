//
//  PayloadDecodingTests.swift
//  SBLib
//
//  Created by Charles Wright on 10/23/24.
//

import XCTest
import os
@testable import Payload


class PayloadDecodingTests: XCTestCase {
    
    func testBasicIntArrayDecoding() {
        _genericDecodingTestCase(type: [Int].self, filename: "int-array")
    }
    
    func _genericDecodingTestCase(type: Decodable.Type, filename: String) {
        // Load test data from the bundle
        guard let url = Bundle.module.url(forResource: filename, withExtension: "payload") else {
            XCTFail("Missing file: \(filename).payload")
            return
        }
        
        // Load the data from the URL
        print("Loading binary payload data from \(url)")
        guard let payload = try? Data(contentsOf: url)
        else {
            XCTFail("Failed to load data from file \(url)")
            return
        }
        print("Loaded \(payload.count) bytes of binary payload data")

        do {
            let decoder = PayloadDecoder()
            let thing = try decoder.decode(type, from: payload)
            XCTAssertNotNil(thing, "Failed to parse payload")
        } catch {
            XCTFail("Failed to decode")
        }
    }
}
