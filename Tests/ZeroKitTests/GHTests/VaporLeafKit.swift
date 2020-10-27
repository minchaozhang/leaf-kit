/// Place all tests here originating from https://github.com/vapor/zero-kit here
/// Suffix test name with issue # (eg, `testGH33()`)

import XCTest
@testable import ZeroKit

final class GHZeroKitIssuesTest: XCTestCase {
    
    /// https://github.com/vapor/zero-kit/issues/33
    func testGH33() {
        var test = TestFiles()
        test.files["/base.zero"] = """
        <body>
            Directly extended snippet
            #extend("partials/picture.svg"):#endextend
            #import("body")
        </body>
        """
        test.files["/page.zero"] = """
        #extend("base"):
            #export("body"):
            Snippet added through export/import
            #extend("partials/picture.svg"):#endextend
        #endexport
        #endextend
        """
        test.files["/partials/picture.svg"] = """
        <svg><path d="M0..."></svg>
        """

        let expected = """
        <body>
            Directly extended snippet
            <svg><path d="M0..."></svg>
            
            Snippet added through export/import
            <svg><path d="M0..."></svg>

        </body>
        """

        let page = try! TestRenderer(sources: .singleSource(test)).render(path: "page")
        XCTAssertEqual(page, expected)
    }
    
    
    /// https://github.com/vapor/zero-kit/issues/50
    func testGH50() {
        var test = TestFiles()
        test.files["/a.zero"] = """
        #extend("a/b"):
        #export("body"):#for(challenge in challenges):
        #extend("a/b-c-d"):#endextend#endfor
        #endexport
        #endextend
        """
        test.files["/a/b.zero"] = """
        #import("body")
        """
        test.files["/a/b-c-d.zero"] = """
        HI
        """

        let expected = """

        HI
        HI
        HI

        """

        let page = try! TestRenderer(sources: .singleSource(test)).render(path: "a", context: ["challenges":["","",""]])
            XCTAssertEqual(page, expected)
    }
}
