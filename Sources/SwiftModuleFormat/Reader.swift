import Foundation
import BitcodeFormat

public final class Reader {
    private typealias BFBlock = BitcodeFormat.Block
    
    public struct Error : ErrorBase {
        public var message: String
        public var path: [String]
        
        public init(message: String,
                    path: [String])
        {
            self.message = message
            self.path = path
        }
        
        public var description: String {
            let pathStr = path.joined(separator: "/")
            return "\(message) at \(pathStr)"
        }
    }
    
    private let file: URL
    
    public init(file: URL) {
        self.file = file
    }
    
    private var module: Module!
    private var moduleBlock: BFBlock!
    private var path: [String] = []
    
    public func read() throws -> Module {
        self.module = Module()
        
        let bcDoc = try BitcodeFormat.Document(file: file)
        
        guard bcDoc.magicNumber == moduleMagicNumber else {
            let str = String(format: "0x%08x", bcDoc.magicNumber)
            throw error("invalid magic number: \(str)")
        }
        
        guard let moduleBlock = (bcDoc.blocks.first { $0.id == Block.ID.MODULE.rawValue }) else {
            throw error("no MODULE_BLOCK block")
        }
        self.moduleBlock = moduleBlock
        
       
        guard let controlBlock = (moduleBlock.blocks.first { $0.id == Block.ID.CONTROL.rawValue }) else {
            throw error("no CONTROL_BLOCK block")
        }
        try readControlBlock(controlBlock)
        
        return self.module!
    }
    
    private func readControlBlock(_ block: BFBlock) throws {
        push(scope: "CONTROL_BLOCK")
        defer { popScope() }

        for record in block.records {
            guard let code = Block.CONTROL.Code(rawValue: record.code) else {
                continue
            }
            push(scope: "\(code)")
            defer { popScope() }
            
            switch code {
            case .MODULE_NAME:
                module.name = try blobString(of: record)
            case .TARGET:
                module.targetTriple = try blobString(of: record)
            case .METADATA:
                if record.values.count < 2 {
                    throw error("invalid value count")
                }
                let major = try int(value(of: record.values[0]))
                let minor = try int(value(of: record.values[1]))
                let modVer = Module.Version(major: major, minor: minor)
                if major == 0, minor == 486 {
                } else {
                    emitWarning("unsupported module version: \(modVer)")
                }
                self.module.moduleVersion = modVer
                let swiftVersionStringBuffer = try blobString(of: record)
                
                var int2 = 0
                if record.values.count >= 3 {
                    int2 = try int(value(of: record.values[2]))
                    let s = swiftVersionStringBuffer.utf8
                    let low = s.startIndex
                    let up = s.index(s.startIndex, offsetBy: int2)
                    let shortVer = String(s[low..<up])
                    self.module.shortSwiftVersion = shortVer
                }
                var int3 = 0
                if record.values.count >= 4 {
                    int3 = try int(value(of: record.values[3]))
                    let s = swiftVersionStringBuffer.utf8
                    let low = s.index(s.startIndex, offsetBy: int2 + 1)
                    let up = s.index(low, offsetBy: int3)
                    let compatVer = String(s[low..<up])
                    self.module.compatibilitySwiftVersion = compatVer
                }
            }
        }
        for block in block.blocks {
            switch block.id {
            case Block.ID.OPTIONS.rawValue:
                try readOptionsBlock(block)
            default:
                break
            }
        }
    }
    
    private func readOptionsBlock(_ block: BFBlock) throws {
        push(scope: "OPTIONS_BLOCK")
        defer { popScope() }
        for record in block.records {
            guard let code = Block.OPTIONS.Code(rawValue: record.code) else {
                continue
            }
            push(scope: "\(code)")
            defer { popScope() }
            
            switch code {
            case .SDK_PATH:
                self.module.sdkPath = try blobString(of: record)
            case .XCC:
                self.module.clangImporterOptions.append(try blobString(of: record))
            case .IS_SIB:
                let record = try decode(Block.OPTIONS.IsSibRecord.self, from: record)
                self.module.isSib = record.isSib
            case .IS_TESTABLE:
                self.module.isTestable = true
            case .ARE_PRIVATE_IMPORTS_ENABLED:
                self.module.arePrivateImportsEnabled = true
            case .RESILIENCE_STRATEGY:
                let record = try decode(Block.OPTIONS.ResilienceStrategyRecord.self, from: record)
                self.module.resilienceStrategy = record.strategy
            }
        }
    }
    
    private func decode<T: DecodableFromRecord>(_ type: T.Type, from record: Record) throws -> T {
        do {
            let decoder = RecordDecoder(record: record)
            let value = try type.init(decoder: decoder)
            return value
        } catch {
            // wrap into path structure
            let message = "decode \(type) failed: \(error)"
            throw self.error(message)
        }
    }
    
    private func scope(_ name: String, _ f: () throws -> Void) rethrows {
        push(scope: name)
        defer { popScope() }
        try f()
    }
    
    private func push(scope: String) {
        path.append(scope)
    }
    private func popScope() {
        precondition(path.count > 0)
        path.removeLast()
    }
    
    private func value(of value: Record.Value) throws -> UInt64 {
        guard let value = value.value else {
            throw error("no value data")
        }
        return value
    }
    
    private func blobString(of record: Record) throws -> String {
        let blob = try self.blob(of: record)
        let str = try decodeUTF8String(data: blob)
        return str
    }
    
    private func blob(of record: Record) throws -> Data {
        guard let blob = record.blob else {
            throw error("no blob data")
        }
        return blob
    }
    
    private func decodeUTF8String(data: Data) throws -> String {
        guard let str = String(data: data, encoding: .utf8) else {
            throw error("UTF-8 decode failed")
        }
        return str
    }
    
    private func emitWarning(_ message: String) {
        emitWarning(error(message))
    }
    
    private func emitWarning(_ error: Error) {
        print("[WARN] \(error)")
    }
    
    private func error(_ message: String) -> Error {
        return Error(message: message,
                     path: path)
    }
    
    private func int(_ a: UInt64) throws -> Int { return try intCast(a) }
    private func intCast<A, R>(_ a: A) throws -> R where A : BinaryInteger, R : BinaryInteger {
        guard let x = R(exactly: a) else {
            throw error("cast int failed: \(A.self) to \(R.self), \(a)")
        }
        return x
    }
}
