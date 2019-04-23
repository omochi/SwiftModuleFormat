import Foundation
import BitcodeFormat

public protocol DecodableFromRecord {
    init(decoder: RecordDecoder) throws
}

public final class RecordDecoder {
    public struct Error : BitcodeFormat.ErrorBase {
        public var message: String
        
        public init(message: String) {
            self.message = message
        }
        
        public var description: String {
            return message
        }
    }
    
    public let record: BitcodeFormat.Record
    public var index: Int
    
    public init(record: BitcodeFormat.Record) {
        self.record = record
        self.index = 0
    }
    
    public func decodeBool() throws -> Bool {
        return try decodeUInt64() != 0
    }
    
    public func decodeUInt64() throws -> UInt64 {
        let value = try decodeValue()
        guard let x = value.value else {
            throw error("not value case: \(value.case)")
        }
        return x
    }
    
    public func decodeInt() throws -> Int {
        return try intCast(decodeUInt64())
    }
    
    public func decodeIntEnum<E>(_ type: E.Type) throws -> E
        where E : RawRepresentable, E.RawValue : BinaryInteger
    {
        let value = try decodeUInt64()
        let intValue: E.RawValue = try intCast(value)
        guard let en = E.init(rawValue: intValue) else {
            throw error("invalid enum value: \(type), \(intValue)")
        }
        return en
    }
        
    private func decodeValue() throws -> BitcodeFormat.Record.Value {
        guard index < record.values.count else {
            throw error("out of range")
        }
        defer { index += 1 }
        return record.values[index]
    }
    
    public func error(_ message: String) -> Error {
        return Error(message: message)
    }
    
    private func intCast<A, R>(_ a: A) throws -> R where A : BinaryInteger, R : BinaryInteger {
        guard let x = R(exactly: a) else {
            throw error("cast int failed: \(A.self) to \(R.self), \(a)")
        }
        return x
    }
}