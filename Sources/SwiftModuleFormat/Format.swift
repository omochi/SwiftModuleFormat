
public let moduleMagicNumber: UInt32 = 0x0E_A8_9C_E2

public enum Block {
    enum ID : UInt32 {
        case MODULE = 8
        case CONTROL
        case INOUT
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
        enum Code : UInt32 {
            case METADATA = 1
            case MODULE_NAME
            case TARGET
        }
        
        public enum METADATA {
            public static let id = Code.METADATA.rawValue
        }
        public enum MODULE_NAME {
            public static let id = Code.MODULE_NAME.rawValue
        }
        public enum TARGET {
            public static let id = Code.TARGET.rawValue
        }
    }
    
    public enum OPTIONS {
        enum Code : UInt32 {
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
            public var strategy: Module.ResilienceStrategy
            
            public init(decoder: RecordDecoder) throws {
                self.strategy = try decoder.decodeIntEnum(Module.ResilienceStrategy.self)
            }
        }
    }
}

