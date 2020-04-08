import XCTest
@testable import FormattedText


class FormattedTextParserTests: XCTestCase {
    func testNoStyle() throws {
        // given
        let tokens = [FormattedTextToken.string(value: "test ")]
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        let node = try parser.parse()
        
        // then
        let expectedNode = TextPart(text: "test ", styles: [])
        XCTAssertEqual(node, expectedNode)
    }
    
    func testOneStyle() throws {
        // given
        let tokens = [FormattedTextToken.string(value: "test "),
                      FormattedTextToken.openingTag(type: .bold),
                      FormattedTextToken.string(value: "toto"),
                      FormattedTextToken.closingTag(type: .bold),
                      FormattedTextToken.string(value: " test 1 < 2")]
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        let node = try parser.parse()
        
        // then
        let expectedNode = TextPart(text: "test ", styles: [])
        XCTAssertEqual(node.text, expectedNode.text)
        XCTAssertEqual(node.styles, expectedNode.styles)
        
        // then
        let expectedChildNode = TextPart(text: "toto", styles: [.bold])
        let childNode = node.next!
        XCTAssertEqual(childNode.text, expectedChildNode.text)
        XCTAssertEqual(childNode.styles, expectedChildNode.styles)
        
        // then
        let expectedChildChildNode = TextPart(text: " test 1 < 2", styles: [])
        let childChildNode = childNode.next!
        XCTAssertEqual(childChildNode.text, expectedChildChildNode.text)
        XCTAssertEqual(childChildNode.styles, expectedChildChildNode.styles)
    }
    
    func testErrorNoClosingTag() {
        // given
        let tokens = [FormattedTextToken.string(value: "test "),
                      FormattedTextToken.openingTag(type: .bold),
                      FormattedTextToken.string(value: "toto"),
                      FormattedTextToken.string(value: " test 1 < 2")]
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        var thrownError: Error?
        XCTAssertThrowsError(try parser.parse()) { error in
            thrownError = error
        }
        
        // then
        XCTAssertTrue(thrownError is FormattedTextParser.Error)
        XCTAssertEqual(thrownError as? FormattedTextParser.Error, .expectedClosingTag(type: .bold))
    }
    
    func testErrorNothing() {
        // given
        let tokens: [FormattedTextToken] = []
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        var thrownError: Error?
        XCTAssertThrowsError(try parser.parse()) { error in
            thrownError = error
        }
        
        // then
        XCTAssertTrue(thrownError is FormattedTextParser.Error)
        XCTAssertEqual(thrownError as? FormattedTextParser.Error, .emptyInput)
    }
    
    func testErrorUnexpectedTag() {
        // given
        let tokens: [FormattedTextToken] = [FormattedTextToken.closingTag(type: .bold),
                                            FormattedTextToken.string(value: "toto")]
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        var thrownError: Error?
        XCTAssertThrowsError(try parser.parse()) { error in
            thrownError = error
        }
        
        // then
        XCTAssertTrue(thrownError is FormattedTextParser.Error)
        XCTAssertEqual(thrownError as? FormattedTextParser.Error, .unexpectedToken(token: .closingTag(type: .bold)))
    }
    
    func testErrorEmptyTag() {
        // given
        let tokens: [FormattedTextToken] = [FormattedTextToken.string(value: "test "),
                                         FormattedTextToken.openingTag(type: .bold),
                                         FormattedTextToken.closingTag(type: .bold),
                                         FormattedTextToken.string(value: "toto")]
        let parser = FormattedTextParser(tokens: tokens)
        
        // when
        var thrownError: Error?
        XCTAssertThrowsError(try parser.parse()) { error in
            thrownError = error
        }
        
        // then
        XCTAssertTrue(thrownError is FormattedTextParser.Error)
        XCTAssertEqual(thrownError as? FormattedTextParser.Error, .emptyTag(type: .bold))
    }
    
    func testErrorNestedSameTag() {
        // given
        let tokens: [FormattedTextToken] = [FormattedTextToken.string(value: "test "),
                                            FormattedTextToken.openingTag(type: .bold),
                                            FormattedTextToken.openingTag(type: .bold),
                                            FormattedTextToken.string(value: "test "),
                                            FormattedTextToken.closingTag(type: .bold),
                                            FormattedTextToken.closingTag(type: .bold),
                                            FormattedTextToken.string(value: "toto")]
        let parser = FormattedTextParser(tokens: tokens)

        // when
        var thrownError: Error?
        XCTAssertThrowsError(try parser.parse()) { error in
            thrownError = error
        }

        // then
        XCTAssertTrue(thrownError is FormattedTextParser.Error)
        XCTAssertEqual(thrownError as? FormattedTextParser.Error, .alreadyPresentTag(type: .bold))
    }
}
