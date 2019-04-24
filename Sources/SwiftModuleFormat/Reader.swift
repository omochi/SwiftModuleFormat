import Foundation
import BitcodeFormat

public final class Reader {
    internal typealias BFBlock = BitcodeFormat.Block
    internal typealias BFReader = BitcodeFormat.Reader
    
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
    
    public struct LinkTask {
        public var name: String
        public var function: (() throws -> Void)
    }
    
    private let file: URL
    
    public init(file: URL) {
        self.file = file
    }
    
    private var module: Module!
    private var isControlBlockRead: Bool = false
    private var path: [String] = []
    private var moduleDocument: Document!
    
    private var identifierData: Data = Data()
    
    private var identifiers: [String] = []
    
    internal var declAndTypesReader: BFReader!
    
    private var linkTasks: [LinkTask] = []
    
    public func read() throws -> Module {
        self.module = Module()
        
        let bcDoc = try BitcodeFormat.Document(file: file)
        self.moduleDocument = bcDoc
        
        guard bcDoc.magicNumber == moduleMagicNumber else {
            let str = String(format: "0x%08x", bcDoc.magicNumber)
            throw error("invalid magic number: \(str)")
        }
        
        guard let moduleBlock = (bcDoc.blocks.first { $0.id == Block.ID.MODULE.rawValue }) else {
            throw error("no MODULE_BLOCK block")
        }
        
        var indexBlock: BFBlock!
        
        for block in moduleBlock.blocks {
            guard let blockID = Block.ID(rawValue: block.id) else {
                continue
            }
            push(scope: "\(blockID)")
            defer { popScope() }
            
            if blockID != .CONTROL {
                try assertControlBlockRead()
            }
            
            switch blockID {
            case .MODULE:
                break
            case .CONTROL:
                try readControlBlock(block)
                isControlBlockRead = true
            case .INPUT:
                try readInputBlock(block)
            case .DECLS_AND_TYPES:
                self.declAndTypesReader = try BFReader(block: block)
                break
            case .IDENTIFIER_DATA:
                for record in block.records {
                    guard let code = Block.IDENTIFIER_DATA.Code(rawValue: record.code) else {
                        continue
                    }
                    push(scope: "\(code)")
                    defer { popScope() }
                    switch code {
                    case .IDENTIFIER_DATA:
                        identifierData = try blob(of: record)
                    }
                }
                break
            case .INDEX:
                indexBlock = block
                break
            case .SIL:
                break
            case .SIL_INDEX:
                break
            case .OPTIONS:
                break
            case .MODULE_DOC:
                break
            case .COMMENT:
                break
            case .DECL_MEMBER_TABLES:
                break
            }
        }
        
        if declAndTypesReader == nil {
            throw error("no DECL_AND_TYPES_BLOCK")
        }
        if indexBlock == nil {
            throw error("no INDEX_BLOCK")
        }
        
        try scope("INDEX_BLOCK") {
            try readIndexBlock(indexBlock)
        }
       
        try linkEntities()
        
        return self.module!
    }
    
    private func assertControlBlockRead() throws {
        guard isControlBlockRead else {
            throw error("CONTROL_BLOCK not read")
        }
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
                let record = try decode(IsSibRecord.self, from: record)
                self.module.isSib = record.isSib
            case .IS_TESTABLE:
                self.module.isTestable = true
            case .ARE_PRIVATE_IMPORTS_ENABLED:
                self.module.arePrivateImportsEnabled = true
            case .RESILIENCE_STRATEGY:
                let record = try decode(ResilienceStrategyRecord.self, from: record)
                self.module.resilienceStrategy = record.strategy
            }
        }
    }
    
    private func readInputBlock(_ block: BFBlock) throws {
        for record in block.records {
            guard let code = Block.INPUT.Code(rawValue: record.code) else {
                continue
            }
            push(scope: "\(code)")
            defer { popScope() }
            switch code {
            case .IMPORTED_MODULE:
                let r = try decode(ImportedModuleRecord.self, from: record)
                module.imports.append(r.asImportEntry())
            case .LINK_LIBRARY:
                let r = try decode(LinkLibrary.self, from: record)
                module.linkLibraries.append(r)
                break
            case .IMPORTED_HEADER:
                let r = try decode(ImportedHeaderRecord.self, from: record)
                module.imports.append(r.asImportEntry())
                break
            case .IMPORTED_HEADER_CONTENTS:
                guard var last = module.imports.last,
                    case .header(var header) = last.entry else
                {
                    throw error("must follow IMPORTED_HEADER")
                }
                header.content = try blob(of: record)
                last.entry = .header(header)
                module.imports[module.imports.count - 1] = last
                break
            case .MODULE_FLAGS:
                break
            case .SEARCH_PATH:
                let r = try decode(SearchPath.self, from: record)
                module.searchPaths.append(r)
                break
            case .FILE_DEPENDENCY:
                break
            case .PARSEABLE_INTERFACE_PATH:
                module.parseableInterface = try blobString(of: record)
                break
            }
        }
    }
    
    private func readIndexBlock(_ block: BFBlock) throws {
        for record in block.records {
            guard let code = Block.INDEX.Code(rawValue: record.code) else {
                continue
            }
            push(scope: "\(code)")
            defer { popScope() }
            switch code {
            case .TYPE_OFFSETS:
                break
            case .DECL_OFFSETS:
                let array = try self.array(of: record)
                
                for (index, value) in array.enumerated() {
                    push(scope: "\(index)")
                    defer { popScope() }
                    
                    let bitOffset = try self.value(of: value)
                    let declReader = DeclReader(moduleReader: self, bitOffset: bitOffset)
                    let decl = try declReader.read()
                    module.decls.append(decl.decl)
                    if let f = decl.linkFunction {
                        let task = LinkTask(name: "\(decl.decl)", function: f)
                        linkTasks.append(task)
                    }
                }
                break
            case .IDENTIFIER_OFFSETS:
                let array = try self.array(of: record)
                
                for (index, value) in array.enumerated() {
                    push(scope: "\(index)")
                    defer { popScope() }
                    
                    let offset = try int(self.value(of: value))
                    let low = identifierData.startIndex + offset
                    guard let up = identifierData[low...].firstIndex(of: 0) else {
                        throw error("no terminate null")
                    }
                    let str = try decodeUTF8String(data: identifierData[low..<up])
                    identifiers.append(str)
                }
                
                break
            case .TOP_LEVEL_DECLS:
                break
            case .OPERATORS:
                break
            case .EXTENSIONS:
                break
            case .CLASS_MEMBERS_FOR_DYNAMIC_LOOKUP:
                break
            case .OPERATOR_METHODS:
                break
            case .OBJC_METHODS:
                break
            case .ENTRY_POINT:
                break
            case .LOCAL_DECL_CONTEXT_OFFSETS:
                break
            case .DECL_CONTEXT_OFFSETS:
                break
            case .LOCAL_TYPE_DECLS:
                break
            case .OPAQUE_RETURN_TYPE_DECLS:
                break
            case .GENERIC_ENVIRONMENT_OFFSETS:
                break
            case .NORMAL_CONFORMANCE_OFFSETS:
                break
            case .SIL_LAYOUT_OFFSETS:
                break
            case .PRECEDENCE_GROUPS:
                break
            case .NESTED_TYPE_DECLS:
                break
            case .DECL_MEMBER_NAMES:
                break
            case .ORDERED_TOP_LEVEL_DECLS:
                break
            case .GENERIC_SIGNATURE_OFFSETS:
                break
            case .SUBSTITUTION_MAP_OFFSETS:
                break
            }
        }
    }
    
    private func linkEntities() throws {
        push(scope: "link")
        defer { popScope() }
        
        for task in linkTasks {
            push(scope: task.name)
            defer { popScope() }
            
            try task.function()
        }
    }
    
    internal func declBaseName(iid: Int) throws -> DeclBaseName {
        if iid == 0 { return .normal("") }
        
        let numS = try int(SpecialIdentifierID.NUM_SPECIAL_IDS.rawValue)
        if iid < numS,
            let siid = SpecialIdentifierID(rawValue: try self.uint8(iid))
        {
            switch siid {
            case .BUILTIN_MODULE_ID,
                 .CURRENT_MODULE_ID,
                 .OBJC_HEADER_MODULE_ID,
                 .NUM_SPECIAL_IDS:
                throw error("invalid")
                
            case .SUBSCRIPT_ID: return .subscript
            case .CONSTRUCTOR_ID: return .constructor
            case .DESTRUCTOR_ID: return .destructor}
        }
        
        let identifier = self.identifiers[iid - numS]
        return .normal(identifier)
    }
    
    internal func identifier(iid: Int) throws -> String {
        return try declBaseName(iid: iid).identifier
    }
    
    internal func decode<T: DecodableFromRecord>(_ type: T.Type, from record: Record) throws -> T {
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
            throw error("not value data")
        }
        return value
    }
    
    private func array(of record: Record) throws -> [Record.Value] {
        guard let array = record.array else {
            throw error("no array")
        }
        return array
    }
    
    private func blobString(of record: Record) throws -> String {
        let blob = try self.blob(of: record)
        let str = try decodeUTF8String(data: blob)
        return str
    }
    
    private func blob(of record: Record) throws -> Data {
        guard let blob = record.blob else {
            throw error("not blob data")
        }
        return blob
    }
    
    private func decodeUTF8String(data: Data) throws -> String {
        guard let str = String(data: data, encoding: .utf8) else {
            throw error("UTF-8 decode failed")
        }
        return str
    }
    
    internal func record(of abbrev: Abbreviation) throws -> Record {
        guard let record = abbrev.record else {
            throw error("not record abbreviation")
        }
        return record
    }
    
    internal func emitWarning(_ message: String) {
        emitWarning(error(message))
    }
    
    internal func emitWarning(_ error: Error) {
        print("[WARN] \(error)")
    }
    
    internal func error(_ message: String) -> Error {
        return Error(message: message,
                     path: path)
    }
    
    private func uint8(_ a: Int) throws -> UInt8 { return try intCast(a) }
    private func int(_ a: UInt8) throws -> Int { return try intCast(a) }
    private func int(_ a: UInt64) throws -> Int { return try intCast(a) }
    private func intCast<A, R>(_ a: A) throws -> R where A : BinaryInteger, R : BinaryInteger {
        guard let x = R(exactly: a) else {
            throw error("cast int failed: \(A.self) to \(R.self), \(a)")
        }
        return x
    }
    
    private func unwrap<R>(_ x: R?) throws -> R {
        guard let r = x else {
            throw error("value is none")
        }
        return r
    }
    
    private func cast<R>(_ ty: R.Type, _ x: Any) throws -> R {
        guard let r = x as? R else {
            throw error("cast failed: \(type(of: x)) to \(R.self)")
        }
        return r
    }
}
