/// Place all tests related to verifying that errors ARE thrown here

import XCTest
@testable import ZeroKit

final class ZeroErrorTests: XCTestCase {

    /// Verify that cyclical references via #extend will throw `ZeroError.cyclicalReference`
    func testCyclicalError() {
        var test = TestFiles()
        test.files["/a.zero"] = "#extend(\"b\")"
        test.files["/b.zero"] = "#extend(\"c\")"
        test.files["/c.zero"] = "#extend(\"a\")"

        do {
            _ = try TestRenderer(sources: .singleSource(test)).render(path: "a")
            XCTFail("Should have thrown ZeroError.cyclicalReference")
        } catch let error as ZeroError {
            switch error.reason {
                case .cyclicalReference(let name, let cycle):
                    XCTAssertEqual([name: cycle], ["a": ["a","b","c","a"]])
                default: XCTFail("Wrong error: \(error.localizedDescription)")
            }
        } catch {
            XCTFail("Wrong error: \(error.localizedDescription)")
        }
    }
    
    /// Verify taht referecing a non-existent template will throw `ZeroError.noTemplateExists`
    func testDependencyError() {
        var test = TestFiles()
        test.files["/a.zero"] = "#extend(\"b\")"
        test.files["/b.zero"] = "#extend(\"c\")"

        do {
            _ = try TestRenderer(sources: .singleSource(test)).render(path: "a")
            XCTFail("Should have thrown ZeroError.noTemplateExists")
        } catch let error as ZeroError {
            switch error.reason {
                case .noTemplateExists(let name): XCTAssertEqual(name,"c")
                default: XCTFail("Wrong error: \(error.localizedDescription)")
            }
        } catch {
            XCTFail("Wrong error: \(error.localizedDescription)")
        }
    }
}
