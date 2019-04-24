import Foundation
import BitcodeFormat

public final class DeclReader {
    public struct Error : ErrorBase {
        public var description: String
    }
    
    public struct Result {
        public var decl: Decl
        public var linkFunction: (() throws -> Void)?
    }
    
    public let moduleReader: Reader
    public let reader: BitcodeFormat.Reader
    public var attrs: [DeclAttribute] = []
    
    public init(moduleReader: Reader,
                bitOffset: UInt64)
    {
        self.moduleReader = moduleReader
        self.reader = moduleReader.declAndTypesReader!
        reader.position = BitcodeFormat.Reader.Position(bitOffset: bitOffset)
    }
    
    public func read() throws -> Result {
        try readAttributes()
        
        let record = try moduleReader.record(of: reader.readAbbreviation())
        
        if let code = Decl.Code(rawValue: record.code) {
            switch code {
            case .CLASS:
                return try readClass(record: record)
            default:
                let decl = UnknownDecl()
                decl.kind = "\(code)"
                decl.attributes = attrs
                return Result(decl: decl, linkFunction: nil)
            }
            
        }
        
        if let code = Decl.OtherCode(rawValue: record.code) {
            switch code {
            case .XREF:
                let decl = UnknownDecl()
                decl.kind = "\(code)"
                decl.attributes = attrs
                return Result(decl: decl, linkFunction: nil)
            default:
                break
            }
        }

        throw moduleReader.error("unknown decl code: \(record.code)")
    }
    
    private func readAttributes() throws {
        loop: while true {
            let position = reader.position
            let record = try moduleReader.record(of: reader.readAbbreviation())
            
            if record.code >= 100,
                let code = DeclAttribute.Code(rawValue: record.code - 100)
            {
                let attr = DeclAttribute(entry: .unknown("\(code)"))
                attrs.append(attr)
                continue loop
            }
            
            if let code = Decl.OtherCode(rawValue: record.code) {
                switch code {
                case .PRIVATE_DISCRIMINATOR,
                     .LOCAL_DISCRIMINATOR,
                     .FILENAME_FOR_PRIVATE:
                    continue loop
                default:
                    break
                }
            }
            
            reader.position = position
            break
        }
    }
    
    private func readClass(record: Record) throws -> Result {
        let r = try moduleReader.decode(ClassRecord.self, from: record)
        
        let d = ClassDecl()
        d.isImplicit = r.isImplicit
        d.isObjC = r.isObjC
        d.requiresStoredPropertyInits = r.requiresStoredPropertyInits
        d.inheritsSuperclassInits = r.inheritsSuperclassInitializers
        
        return Result(decl: d) {
            d.name = try self.moduleReader.identifier(iid: r.nameID)
        }
    }
}
