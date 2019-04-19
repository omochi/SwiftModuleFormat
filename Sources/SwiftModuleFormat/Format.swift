
public let moduleMagicNumber: UInt32 = 0x0E_A8_9C_E2

public enum Block {
    internal enum ID : UInt32 {
        case module = 8
        case control
        case input
        case declsAndTypes
        case identifierData
        case index
        case sil
        case silIndex
        case options
        case moduleDoc = 96
        case comment
        case declMemberTables
    }
    
    public enum Module {
        public static let id: UInt32 = ID.module.rawValue
    }
}

