import XCTest
@testable import FormattedText

class FormattedTextLexerTests: XCTestCase {
    func testSentenceOnly() {
        // given
        let text = "test"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "test")
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testOpeningTagOnlyOnly() {
        // given
        let text = "<b>"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.openingTag(type: .bold)
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testFakeOpeningTagOnlyOnly() {
        // given
        let text = "<%>"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "<%>")
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testClosingTagOnlyOnly() {
        // given
        let text = "</b>"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.closingTag(type: .bold)
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testFakeClosingTagOnlyOnly() {
        // given
        let text = "</%>"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "</%>")
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testSentenceWithOneBoldPart() {
        // given
        let text = "test <b>toto</b> test."
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "test "),
            FormattedTextToken.openingTag(type: .bold),
            FormattedTextToken.string(value: "toto"),
            FormattedTextToken.closingTag(type: .bold),
            FormattedTextToken.string(value: " test."),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testSentenceWithOneFakeBoldPart() {
        // given
        let text = "test <b"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "test <b"),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testEdgeCaseTag1() {
        // given
        let text = "<"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "<"),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testEdgeCaseTag2() {
        // given
        let text = "<b"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "<b"),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testEdgeCaseTag3() {
        // given
        let text = "</"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "</"),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testEdgeCaseTag4() {
        // given
        let text = "</b"
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens = [
            FormattedTextToken.string(value: "</b"),
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
    
    func testEdgeCaseEmpty() {
        // given
        let text = ""
        let scanner = FormattedTextLexer(text: text)
        
        // when
        let tokens = scanner.scan()
        
        // then
        let expectedTokens: [FormattedTextToken] = []
        XCTAssertEqual(tokens, expectedTokens)
    }
}
