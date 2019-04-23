import Foundation
import BitcodeFormat

public final class Module : CopyInitializable {
    public struct Version : CustomStringConvertible {
        public var major: Int
        public var minor: Int
        
        public var description: String {
            return "\(major).\(minor)"
        }
    }

    // CONTROL
    public var moduleVersion: Version
    public var name: String?
    public var targetTriple: String?
    public var shortSwiftVersion: String?
    public var compatibilitySwiftVersion: String?
    
    // OPTIONS
    public var sdkPath: String?
    public var clangImporterOptions: [String] = []
    public var isSib: Bool = false
    public var isTestable: Bool = false
    public var arePrivateImportsEnabled: Bool = false
    public var resilienceStrategy: ResilienceStrategy = .default
    
    // INPUT
    public var imports: [Import] = []
    public var linkLibraries: [LinkLibrary] = []
    public var searchPaths: [SearchPath] = []
    public var parseableInterface: String?
    
    // IDENTIFIER_DATA
    public var identifierData: Data = Data()
    
    public init() {
        self.moduleVersion = Version(major: 0, minor: 0)
    }
    
    public convenience init(file: URL) throws {
        let reader = Reader(file: file)
        let mod = try reader.read()
        self.init(copy: mod)
    }
}

public enum ResilienceStrategy : Int {
    case `default` = 0
    case resilient
}

public struct Import {
    public enum Control : UInt8 {
        case normal = 0
        case exported
        case implementationOnly
    }
    
    public struct Module {
        public var isScoped: Bool
        public var path: [String]
    }
    
    public struct Header {
        public var size: UInt64
        public var modTime: UInt64
        public var path: String
        public var content: Data
    }
    
    public enum Entry {
        case module(Module)
        case header(Header)
    }
    
    public var control: Control
    public var entry: Entry

    public init(control: Control,
                entry: Entry)
    {
        self.control = control
        self.entry = entry
    }
}

public struct LinkLibrary : DecodableFromRecord {
    public enum Kind : UInt8 {
        case library = 0
        case framework
    }
    
    public var kind: Kind
    public var isForced: Bool
    public var name: String
    
    public init(decoder: RecordDecoder) throws {
        self.kind = try decoder.decodeIntEnum(Kind.self)
        self.isForced = try decoder.decodeBool()
        self.name = try decoder.decodeString()
    }
}

public struct SearchPath : DecodableFromRecord {
    public var path: String
    public var isFramework: Bool
    public var isSystem: Bool
    
    public init(decoder: RecordDecoder) throws {
        self.isFramework = try decoder.decodeBool()
        self.isSystem = try decoder.decodeBool()
        self.path = try decoder.decodeString()
    }
    
}
