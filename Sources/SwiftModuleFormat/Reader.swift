import Foundation
import BitcodeFormat

public final class Reader {
    public struct Error : ErrorBase {
        public var message: String
        
        public init(message: String) {
            self.message = message
        }
        
        public var description: String {
            return message
        }
    }
    
    private let file: URL
    
    public init(file: URL) {
        self.file = file
    }
    
    private var moduleBlock: Block!
    
    public func read() throws -> Module {
        let bcDoc = try BitcodeFormat.Document(file: file)
        
        guard bcDoc.magicNumber == moduleMagicNumber else {
            let str = String(format: "0x%08x", bcDoc.magicNumber)
            throw error("invalid magic number: \(str)")
        }
        
        guard let block = (bcDoc.blocks.first { $0.id == Block.Module.id }) else {
            throw error("no MODULE_BLOCK block")
        }
        
        fatalError("TODO")
    }
    
    private func error(_ message: String) -> Error {
        return Error(message: message)
    }
}
