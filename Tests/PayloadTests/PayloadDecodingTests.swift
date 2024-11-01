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
    
    func testGenericTypeInference() throws {
        
        enum TestError: Error {
            case madeUpError
        }
        
        class GenericClass {
            func foo(_ type: Int.Type) throws {
                print("foo Int")
            }
            
            func foo(_ type: Int64.Type) throws {
                print("foo Int64")
            }
            
            /*
            // Un-comment this to have the g.foo(UInt32.self) call below go to this function instead of the BinaryInteger version
            func foo(_ type: UInt32.Type) throws {
                print("foo UInt32")
            }
            */
            
            func foo<T>(_ type: T.Type) throws where T: BinaryInteger & Codable {
                print("foo BinaryInteger (type = \(T.self))")
            }
            
            func foo(_ type: String.Type) throws {
                print("foo String")
            }
            
            func foo<T>(_ type: T.Type) throws where T: Codable {
                print("foo Generic (type = \(T.self))")
            }
            
            func fooArray<T>(_ type: [T].Type) throws {
                print("foo Array (type = \(T.self))")
            }
            
            func foo<T>(_ type: T.Type) throws where T: ExpressibleByArrayLiteral & Codable {
                print("foo ExpressibleByArrayLiteral (type = \(T.self))")
            }
        }
        
        let g = GenericClass()
        try g.foo(Int.self)
        try g.foo(Int64.self)
        try g.foo(UInt32.self)
        try g.foo(String.self)
        //try g.foo(Date.self)
        try g.foo([Int].self)
    }
}
