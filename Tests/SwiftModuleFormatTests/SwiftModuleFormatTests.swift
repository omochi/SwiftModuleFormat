import XCTest
import SwiftModuleFormat
import BitcodeFormat

final class SwiftModuleFormatTests: XCTestCase {
    func test1() throws {
        let file = try SwiftModuleFormat.Resources.findResourceDirectory()
            .appendingPathComponent("Test")
            .appendingPathComponent("xcbox.swiftmodule")
        let module = try Module(file: file)
        dump(module)
    }
}
