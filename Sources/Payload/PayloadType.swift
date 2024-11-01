//
//  PayloadType.swift
//  SBLib
//
//  Created by Charles Wright on 10/18/24.
//

/**
 * Our internal type letters:
 *
 * a - Array
 * 8 - Uint8Array
 * b - Boolean
 * d - Date
 * i - Integer (32 bit signed)
 * j - JSON (stringify)
 * m - Map
 * 0 - Null
 * n - Number (JS internal)
 * o - Object
 * s - String
 * t - Set
 * u - Undefined
 * v - Dataview
 * x - ArrayBuffer
 *
 */

enum PayloadType: String, Codable {
    case array = "a"
    case uint8Array = "8"
    case boolean = "b"
    case date = "d"
    case integer = "i"
    case json = "j"
    case map = "m"
    case null = "0"
    case double = "n"
    case object = "o"
    case string = "s"
    case set = "t"
    case undefined = "u"
    case dataview = "v"
    case data = "x"
}
