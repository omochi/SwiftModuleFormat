import Foundation
import BitcodeFormat

public enum Resources {
    public static func findResourceDirectory() throws -> URL {
        let env = try RuntimeEnvironment.detect()
        switch env {
        case .swiftPM, .xcode, .xctest:
            let repoDir = URL(fileURLWithPath: String(#file))
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            return repoDir.appendingPathComponent("Resources")
        case .unknown:
            fatalError("unsupported runtime environment")
        }
    }
}
