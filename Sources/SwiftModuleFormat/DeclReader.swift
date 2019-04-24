import Foundation
import BitcodeFormat

public final class DeclReader {
    public struct Error : ErrorBase {
        public var description: String
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
    
    public func read() throws -> Decl {
        try readAttributes()
        
        let record = try moduleReader.record(of: reader.readAbbreviation())
        
        if let code = Decl.Code(rawValue: record.code) {
            
            switch code {
            default:
                let decl = UnknownDecl()
                decl.name = "\(code)"
                decl.attributes = attrs
                return decl
            }
            
        }
        
        if let code = Decl.OtherCode(rawValue: record.code) {
            switch code {
            case .XREF:
                let decl = UnknownDecl()
                decl.name = "\(code)"
                decl.attributes = attrs
                return decl
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
}
