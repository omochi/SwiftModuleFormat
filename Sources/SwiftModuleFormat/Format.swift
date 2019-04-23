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
    }
}

