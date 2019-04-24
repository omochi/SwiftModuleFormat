import Foundation

public let moduleMagicNumber: UInt32 = 0x0E_A8_9C_E2

public enum Block {
    public enum ID : UInt32 {
        case MODULE = 8
        case CONTROL
        case INPUT
        case DECLS_AND_TYPES
        case IDENTIFIER_DATA
        case INDEX
        case SIL
        case SIL_INDEX
        case OPTIONS
        case MODULE_DOC = 96
        case COMMENT
        case DECL_MEMBER_TABLES
    }
    
    public enum MODULE {
    }
    
    public enum CONTROL {
        public enum Code : UInt32 {
            case METADATA = 1
            case MODULE_NAME
            case TARGET
        }
    }
    
    public enum OPTIONS {
        public enum Code : UInt32 {
            case SDK_PATH = 1
            case XCC
            case IS_SIB
            case IS_TESTABLE
            case RESILIENCE_STRATEGY
            case ARE_PRIVATE_IMPORTS_ENABLED
        }
    }
    
    public enum INPUT {
        public enum Code : UInt32 {
            case IMPORTED_MODULE = 1
            case LINK_LIBRARY
            case IMPORTED_HEADER
            case IMPORTED_HEADER_CONTENTS
            case MODULE_FLAGS
            case SEARCH_PATH
            case FILE_DEPENDENCY
            case PARSEABLE_INTERFACE_PATH
        }
    }
    
    public enum IDENTIFIER_DATA {
        public enum Code : UInt32 {
            case IDENTIFIER_DATA = 1
        }
    }
    
    public enum INDEX {
        public enum Code : UInt32 {
            case TYPE_OFFSETS = 1
            case DECL_OFFSETS
            case IDENTIFIER_OFFSETS
            case TOP_LEVEL_DECLS
            case OPERATORS
            case EXTENSIONS
            case CLASS_MEMBERS_FOR_DYNAMIC_LOOKUP
            case OPERATOR_METHODS

            case OBJC_METHODS

            case ENTRY_POINT
            case LOCAL_DECL_CONTEXT_OFFSETS
            case DECL_CONTEXT_OFFSETS
            case LOCAL_TYPE_DECLS
            case OPAQUE_RETURN_TYPE_DECLS
            case GENERIC_ENVIRONMENT_OFFSETS
            case NORMAL_CONFORMANCE_OFFSETS
            case SIL_LAYOUT_OFFSETS

            case PRECEDENCE_GROUPS
            case NESTED_TYPE_DECLS
            case DECL_MEMBER_NAMES
            
            case ORDERED_TOP_LEVEL_DECLS
            
            case GENERIC_SIGNATURE_OFFSETS
            case SUBSTITUTION_MAP_OFFSETS
        }
    }
}

public struct IsSibRecord : DecodableFromRecord {
    public var isSib: Bool
    
    public init(decoder: RecordDecoder) throws {
        self.isSib = try decoder.decodeBool()
    }
}

public struct ResilienceStrategyRecord : DecodableFromRecord {
    public var strategy: ResilienceStrategy
    
    public init(decoder: RecordDecoder) throws {
        self.strategy = try decoder.decodeIntEnum(ResilienceStrategy.self)
    }
}

public struct ImportedModuleRecord : DecodableFromRecord {
    public var control: Import.Control
    public var isScoped: Bool
    public var path: [String]
    
    public init(decoder: RecordDecoder) throws {
        self.control = try decoder.decodeIntEnum(Import.Control.self)
        self.isScoped = try decoder.decodeBool()
        self.path = try decoder.decodeNullSeparatedStrings()
    }
    
    public func asImportEntry() -> Import {
        let module = Import.Module(isScoped: isScoped, path: path)
        return Import(control: control,
                      entry: .module(module))
    }
}

public struct ImportedHeaderRecord : DecodableFromRecord {
    public var isExported: Bool
    public var fileSize: UInt64
    public var fileModTime: UInt64
    public var path: String
    
    public init(decoder: RecordDecoder) throws {
        self.isExported = try decoder.decodeBool()
        self.fileSize = try decoder.decodeUInt64()
        self.fileModTime = try decoder.decodeUInt64()
        self.path = try decoder.decodeString()
    }
    
    public func asImportEntry() -> Import {
        let header = Import.Header(size: fileSize,
                                   modTime: fileModTime,
                                   path: path,
                                   content: Data())
        return Import(control: isExported ? .exported : .normal,
                      entry: .header(header))
    }
}

public struct ClassRecord : DecodableFromRecord {
    public var nameID: Int
    public var contextID: Int
    public var isImplicit: Bool
    public var isObjC: Bool
    public var requiresStoredPropertyInits: Bool
    public var inheritsSuperclassInitializers: Bool
    public var genericEnvID: Int
    public var superclassID: Int
    public var rawAccessLevel: UInt8
    public var numConformances: Int
    public var rawInheritedIDs: [Int]
    public init(decoder d: RecordDecoder) throws {
        nameID = try d.decodeInt()
        contextID = try d.decodeInt()
        isImplicit = try d.decodeBool()
        isObjC = try d.decodeBool()
        requiresStoredPropertyInits = try d.decodeBool()
        inheritsSuperclassInitializers = try d.decodeBool()
        genericEnvID = try d.decodeInt()
        superclassID = try d.decodeInt()
        rawAccessLevel = try d.decodeUInt8()
        numConformances = try d.decodeInt()
        rawInheritedIDs = try d.decodeArray { (d) in try d.decodeInt() }
    }
}
