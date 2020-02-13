//
//  JSONDecoderEx.swift
//  JSONDecoderEx
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//
import Foundation


/// If a type conform the JSONDecoderExpressibleByNilLiteral protocol, it should automatically create default for value not found.
public protocol JSONDecoderExExpressibleByNilLiteral {
    init()
}

/// A enhanced JSON decoder.
open class JSONDecoderEx: JSONDecoder {

    /// The strategy to use for Non-Type-Matching values.
    public enum NonMatchingDecodingStrategy {

        /// Throw upon encountering non-matching values. This is the default strategy.
        case `throw`

        /// Try to convert the value to the matching type.
        case automatically
    }

    /// The strategy to use for Not-Found-Key values.
    public enum NotFoundDecodingStrategy {

        /// Throw upon encountering not-found values. This is the default strategy.
        case `throw`

        /// Try to generate the defaults.
        case automatically
    }

    /// The strategy to use for Non-Type-Matching values. Defaults to `.automatically`.
    open var nonMatchingDecodingStrategy: NonMatchingDecodingStrategy = .automatically

    /// The strategy to use for Not-Found-Key values. Defaults to `.automatically`.
    open var notFoundDecodingStrategy: NotFoundDecodingStrategy = .automatically

    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    open override func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Use Detector to get the original JSONDecoder.
        let decoder = try _JSONDecoder(decoder: super.decode(_JSONDecoderDetector.self, from: data).decoder, options: .init(notFoundDecodingStrategy: notFoundDecodingStrategy, nonMatchingDecodingStrategy: nonMatchingDecodingStrategy))

        // Parse the object using the new decoder.
        return try type.init(from: decoder)
    }
}

/// A enhanced JSON decoder.
private struct _JSONDecoder: Decoder, SingleValueDecodingContainer {

    /// The original JSONDecoder.
    let decoder: Decoder
    let options: _JSONDecoderOptioins

    /// The path of coding keys taken to get to this point in decoding.
    var codingPath: [CodingKey] {
        return decoder.codingPath
    }

    /// Any contextual information set by the user for decoding.
    var userInfo: [CodingUserInfoKey: Any] {
        return decoder.userInfo
    }

    /// Returns the data stored in this decoder as represented in a container
    /// keyed by the given key type.
    ///
    /// - parameter type: The key type to use for the container.
    /// - returns: A keyed decoding container view into this decoder.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not a keyed container.
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        return try .init(_JSONKeyedDecodingContainer<Key>(container: decoder.container(keyedBy: type), options: options))
    }

    /// Returns the data stored in this decoder as represented in a container
    /// appropriate for holding values with no keys.
    ///
    /// - returns: An unkeyed container view into this decoder.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not an unkeyed container.
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try _JSONUnkeyedDecodingContainer(container: decoder.unkeyedContainer(), options: options)
    }

    /// Returns the data stored in this decoder as represented in a container
    /// appropriate for holding a single primitive value.
    ///
    /// - returns: A single value container view into this decoder.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not a single value container.
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    // MARK: SingleValueDecodingContainer

    /// Decodes a null value.
    ///
    /// - returns: Whether the encountered value was null.
    func decodeNil() -> Bool {
        return (try? decoder.singleValueContainer().decodeNil()) ?? false
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Bool.Type) throws -> Bool {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: String.Type) throws -> String {
        return try options.string(in: decoder.singleValueContainer())
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Double.Type) throws -> Double {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Float.Type) throws -> Float {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Int.Type) throws -> Int {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: UInt.Type) throws -> UInt {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try options.number(in: decoder.singleValueContainer(), to: type)
    }

    /// Decodes a single value of the given type.
    ///
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   cannot be converted to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null.
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try type.init(from: self)
    }
}

/// A enhanced JSON decoder keyed decoding container.
private struct _JSONKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K

    /// The original JSON decoder container.
    let container: KeyedDecodingContainer<K>
    let options: _JSONDecoderOptioins

    /// The path of coding keys taken to get to this point in decoding.
    var codingPath: [CodingKey] {
        return container.codingPath
    }

    /// All the keys the decoder has for this container.
    ///
    /// Different keyed containers from the same decoder may return different
    /// keys here, because it is possible to encode with multiple key types
    /// which are not convertible to one another. This should report all keys
    /// present which are convertible to the requested type.
    var allKeys: [K] {
        return container.allKeys
    }

    /// Returns a Boolean value indicating whether the decoder contains a value
    /// associated with the given key.
    ///
    /// The value associated with the given key may be a null value as
    /// appropriate for the data format.
    ///
    /// - parameter key: The key to search for.
    /// - returns: Whether the `Decoder` has an entry for the given key.
    func contains(_ key: Key) -> Bool {
        return container.contains(key)
    }

    /// Decodes a null value for the given key.
    ///
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: Whether the encountered value was null.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    func decodeNil(forKey key: Key) throws -> Bool {
        return try container.decodeNil(forKey: key)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return false
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return ""
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return 0
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        // If the value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            // Only support JSONDecoderExpressibleByNilLiteral created.
            if let type = type as? JSONDecoderExExpressibleByNilLiteral.Type, let value = type.init() as? T {
                return value
            }

            return try container.decode(type, forKey: key)
        }

        // Date and data cannot be processed.
        if type is Date.Type || type is Data.Type {
            return try container.decode(type, forKey: key)
        }

        return try singleValueContainer(forKey: key).decode(type)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Decodes a value of the given type for the given key, if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with `key`, or if the value is null. The difference between
    /// these states can be distinguished with a `contains(_:)` call.
    ///
    /// - parameter type: The type of value to decode.
    /// - parameter key: The key that the decoded value is associated with.
    /// - returns: A decoded value of the requested type, or `nil` if the
    ///   `Decoder` does not have an entry associated with the given key, or if
    ///   the value is a null value.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        // If the key or value is nil, return the default value directly.
        guard !options.isNull(container, forKey: key) else {
            return nil
        }

        // Date and data cannot be processed.
        if type is Date.Type || type is Data.Type {
            return try container.decodeIfPresent(type, forKey: key)
        }

        // Decode with custom decoder.
        return try decode(type, forKey: key)
    }

    /// Returns the data stored for the given key as represented in a container
    /// keyed by the given key type.
    ///
    /// - parameter type: The key type to use for the container.
    /// - parameter key: The key that the nested container is associated with.
    /// - returns: A keyed decoding container view into `self`.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not a keyed container.
    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return try .init(_JSONKeyedDecodingContainer<NestedKey>(container: container.nestedContainer(keyedBy: type, forKey: key), options: options))
    }

    /// Returns the data stored for the given key as represented in an unkeyed
    /// container.
    ///
    /// - parameter key: The key that the nested container is associated with.
    /// - returns: An unkeyed decoding container view into `self`.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not an unkeyed container.
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try _JSONUnkeyedDecodingContainer(container: container.nestedUnkeyedContainer(forKey: key), options: options)
    }

    /// Returns a `Decoder` instance for decoding `super` from the container
    /// associated with the default `super` key.
    ///
    /// Equivalent to calling `superDecoder(forKey:)` with
    /// `Key(stringValue: "super", intValue: 0)`.
    ///
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the default `super` key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the default `super` key.
    func superDecoder() throws -> Decoder {
        return try _JSONDecoder(decoder: container.superDecoder(), options: options)
    }

    /// Returns a `Decoder` instance for decoding `super` from the container
    /// associated with the given key.
    ///
    /// - parameter key: The key to decode `super` for.
    /// - returns: A new `Decoder` to pass to `super.init(from:)`.
    /// - throws: `DecodingError.keyNotFound` if `self` does not have an entry
    ///   for the given key.
    /// - throws: `DecodingError.valueNotFound` if `self` has a null entry for
    ///   the given key.
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try _JSONDecoder(decoder: container.superDecoder(forKey: key), options: options)

    }

    /// Returns an encoding container appropriate for holding a single primitive
    /// value.
    ///
    /// You must use only one kind of top-level encoding container. This method
    /// must not be called after a call to `unkeyedContainer()` or
    /// `container(keyedBy:)`, or after encoding a value through a call to
    /// `singleValueContainer()`
    ///
    /// - returns: A new empty single value container.
    func singleValueContainer(forKey key: Key) throws -> SingleValueDecodingContainer {
        return try _JSONDecoder(decoder: container.superDecoder(forKey: key), options: options)
    }
}

/// A enhanced JSON decoder unkeyed decoding container.
private struct _JSONUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    /// The original JSON decoder container.
    var container: UnkeyedDecodingContainer
    var options: _JSONDecoderOptioins

    /// The path of coding keys taken to get to this point in decoding.
    public var codingPath: [CodingKey] {
        return container.codingPath
    }

    /// The number of elements contained within this container.
    ///
    /// If the number of elements is unknown, the value is `nil`.
    public var count: Int? {
        return container.count
    }

    /// A Boolean value indicating whether there are no more elements left to be
    /// decoded in the container.
    public var isAtEnd: Bool {
        return container.isAtEnd
    }

    /// The current decoding index of the container (i.e. the index of the next
    /// element to be decoded.) Incremented after every successful decode call.
    public var currentIndex: Int {
        return container.currentIndex
    }

    /// Decodes a null value.
    ///
    /// If the value is not null, does not increment currentIndex.
    ///
    /// - returns: Whether the encountered value was null.
    /// - throws: `DecodingError.valueNotFound` if there are no more values to
    ///   decode.
    mutating func decodeNil() throws -> Bool {
        return try container.decodeNil()
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: String.Type) throws -> String {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Double.Type) throws -> Double {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Float.Type) throws -> Float {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Int.Type) throws -> Int {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A value of the requested type, if present for the given key
    ///   and convertible to the requested type.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {

        // Date and data can't be processed.
        if type is Date.Type || type is Data.Type {
            return try container.decode(type)
        }

        return try singleValueContainer().decode(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: String.Type) throws -> String? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a value of the given type, if present.
    ///
    /// This method returns `nil` if the container has no elements left to
    /// decode, or if the value is null. The difference between these states can
    /// be distinguished by checking `isAtEnd`.
    ///
    /// - parameter type: The type of value to decode.
    /// - returns: A decoded value of the requested type, or `nil` if the value
    ///   is a null value, or if there are no more elements to decode.
    /// - throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    mutating func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T? {
        return try container.decodeIfPresent(type)
    }

    /// Decodes a nested container keyed by the given type.
    ///
    /// - parameter type: The key type to use for the container.
    /// - returns: A keyed decoding container view into `self`.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not a keyed container.
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return try .init(_JSONKeyedDecodingContainer<NestedKey>(container: container.nestedContainer(keyedBy: type), options: options))
    }

    /// Decodes an unkeyed nested container.
    ///
    /// - returns: An unkeyed decoding container view into `self`.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not an unkeyed container.
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try _JSONUnkeyedDecodingContainer(container: container.nestedUnkeyedContainer(), options: options)
    }

    /// Decodes a nested container and returns a `Decoder` instance for decoding
    /// `super` from that container.
    ///
    /// - returns: A new `Decoder` to pass to `super.init(from:)`.
    /// - throws: `DecodingError.valueNotFound` if the encountered encoded value
    ///   is null, or of there are no more values to decode.
    mutating func superDecoder() throws -> Decoder {
        return try _JSONDecoder(decoder: container.superDecoder(), options: options)
    }

    /// Returns the data stored in this decoder as represented in a container
    /// appropriate for holding a single primitive value.
    ///
    /// - returns: A single value container view into this decoder.
    /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
    ///   not a single value container.
    mutating func singleValueContainer() throws -> SingleValueDecodingContainer {
        return try _JSONDecoder(decoder: container.superDecoder(), options: options)
    }
}

/// A detector in order to obtain the original decoder of JSONDecoder.
private struct _JSONDecoderDetector: Decodable {

    /// The original JSONDeocder in container.
    let decoder: Decoder
    init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}

/// Map to oc object.
private class _JSONDecoderConverter: NSObject {

    @objc var Int: Int = 0
    @objc var Int8: Int8 = 0
    @objc var Int16: Int16 = 0
    @objc var Int32: Int32 = 0
    @objc var Int64: Int64 = 0

    @objc var UInt: Int = 0
    @objc var UInt8: Int8 = 0
    @objc var UInt16: Int16 = 0
    @objc var UInt32: Int32 = 0
    @objc var UInt64: Int64 = 0

    @objc var Float: Double = 0
    @objc var Double: Double = 0

    @objc var Bool: Bool = false

    override func setNilValueForKey(_ key: String) {
        // Nothing.
    }
}

/// Some decoding options
private struct _JSONDecoderOptioins {

    /// Some decoding options.
    let notFoundDecodingStrategy: JSONDecoderEx.NotFoundDecodingStrategy
    let nonMatchingDecodingStrategy: JSONDecoderEx.NonMatchingDecodingStrategy

    // Check whether the key-value specified is legal.
    func isNull<K: CodingKey>(_ container: KeyedDecodingContainer<K>, forKey key: K) -> Bool {
        // Check the feature is enabled.
        guard notFoundDecodingStrategy == .automatically else {
            return false
        }

        // Check the key is exists.
        guard container.contains(key) else {
            return true
        }

        // Check the value is exists.
        return (try? container.decodeNil(forKey: key)) ?? false
    }

    /// Gets value from container.
    func value(in container: SingleValueDecodingContainer) -> Any? {

        // Try convert to a boolean value.
        if let value = try? container.decode(Bool.self) {
            return NSNumber(value: value)
        }

        // Try convert to a 64bit unsigned int value.
        if let value = try? container.decode(UInt64.self) {
            return NSNumber(value: value)
        }

        // Try convert to a 64bit signed int value.
        if let value = try? container.decode(Int64.self) {
            return NSNumber(value: value)
        }

        // Try convert to a 64bit signed double value.
        if let value = try? container.decode(Double.self) {
            return NSNumber(value: value)
        }

        // It can only be a string, if it fails to throw an execption.
        return try? container.decode(String.self)
    }

    /// Gets number from container.
    func number<T: Decodable>(in container: SingleValueDecodingContainer, to type: T.Type) throws -> T {
        do {

            return try container.decode(type)

        } catch let error as DecodingError {

            switch error {
            case .typeMismatch,
                 .dataCorrupted:

                // Check the type supports convert.
                let convert = _JSONDecoderConverter()
                if !convert.responds(to: Selector("\(type)")) {
                    throw error
                }

                // Use the automatic convert mechanism of objective-c.
                convert.setValue(value(in: container), forKey: "\(type)")
                if let value = convert.value(forKey: "\(type)") as? T {
                    return value
                }

                throw error

            default:
                throw error
            }

        } catch {
            throw error
        }
    }

    /// Force prase to be a string type.
    func string(in container: SingleValueDecodingContainer) throws -> String {
        // Try convert to a boolean value.
        if let value = try? container.decode(Bool.self).description {
            return value
        }
        // Try convert to a 64bit unsigned int value.
        if let value = try? container.decode(UInt64.self).description {
            return value
        }
        // Try convert to a 64bit signed int value.
        if let value = try? container.decode(Int64.self).description {
            return value
        }
        // Try convert to a 64bit signed double value.
        if let value = try? container.decode(Double.self).description {
            return value
        }
        // It can only be a string, if it fails to throw an execption.
        return try container.decode(String.self)
    }
}

extension Date: JSONDecoderExExpressibleByNilLiteral {}
extension Array: JSONDecoderExExpressibleByNilLiteral {}
extension Dictionary: JSONDecoderExExpressibleByNilLiteral {}
