import XCTest
@testable import ZeroKit

final class SerializerTests: XCTestCase {
    func testComplex() throws {
        let input = """
        hello, #(name)!
        #for(skill in skills):
        you're pretty good at #(skill)
        #endfor

        #if(false): don't show
        #elseif(true):
        it works!
        #endif

        #if(lowercased(me) == "logan"):
        expression resolution worked!!
        #endif
        """

        let syntax = try! parse(input)
        let name = ZeroData(.string("vapor"))

        let me = ZeroData(.string("LOGAN"))
        let running = ZeroData(.string("running"))
        let walking = ZeroData(.string("walking"))
        let skills = ZeroData(.array([running, walking]))
        var serializer = ZeroSerializer(ast: syntax, context: ["name": name, "skills": skills, "me": me])
        let serialized = try serializer.serialize()
        print(serialized)
        print()
//        let syntax = try! altParse(input)
//        let output = syntax.map { $0.description } .joined(separator: "\n")
//        XCTAssertEqual(output, expectation)
    }

    func testNestedKeyPathLoop() throws {
        let input = """
        #for(person in people):
        hello #(person.name)
        #for(skill in person.skills):
        you're pretty good at #(skill)
        #endfor
        #endfor
        """

        let syntax = try! parse(input)
        let people = ZeroData(.array([
            ZeroData(.dictionary([
                "name": "LOGAN",
                "skills": ZeroData(.array([
                    "running",
                    "walking"
                ]))
            ]))
        ]))

        var serializer = ZeroSerializer(ast: syntax, context: ["people": people])
        let serialized = try serializer.serialize()
        let str = serialized.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(str, """
        hello LOGAN

        you're pretty good at running

        you're pretty good at walking
        """)
    }

    func testInvalidNestedKeyPathLoop() throws {
        let input = """
        #for(person in people):
        hello #(person.name)
        #for(skill in person.profile.skills):
        you're pretty good at #(skill)
        #endfor
        #endfor
        """

        let syntax = try! parse(input)
        let people = ZeroData(.array([
            ZeroData(.dictionary([
                "name": "LOGAN",
                "skills": ZeroData(.array([
                    "running",
                    "walking"
                ]))
            ]))
        ]))

        var serializer = ZeroSerializer(ast: syntax, context: ["people": people])

        XCTAssertThrowsError(try serializer.serialize()) { error in
            XCTAssertEqual("\(error)", "expected dictionary at key: person.profile")
        }
    }
}
