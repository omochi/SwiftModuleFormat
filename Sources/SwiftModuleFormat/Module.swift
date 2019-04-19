import Foundation
import BitcodeFormat

public final class Module : CopyInitializable {
    public convenience init(file: URL) throws {
        let reader = Reader(file: file)
        let mod = try reader.read()
        self.init(copy: mod)
    }
}
