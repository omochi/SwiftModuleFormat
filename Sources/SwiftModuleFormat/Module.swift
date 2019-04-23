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
    
    public enum ResilienceStrategy : Int {
        case `default` = 0
        case resilient
    }
    
    public var moduleVersion: Version
    public var name: String?
    public var targetTriple: String?
    public var shortSwiftVersion: String?
    public var compatibilitySwiftVersion: String?
    public var sdkPath: String?
    public var clangImporterOptions: [String] = []
    public var isSib: Bool = false
    public var isTestable: Bool = false
    public var arePrivateImportsEnabled: Bool = false
    public var resilienceStrategy: ResilienceStrategy = .default
    
    public init() {
        self.moduleVersion = Version(major: 0, minor: 0)
    }
    
    public convenience init(file: URL) throws {
        let reader = Reader(file: file)
        let mod = try reader.read()
        self.init(copy: mod)
    }
}
