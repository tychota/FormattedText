/**
The purpose of `FormattedTextParser` is to transform an array of `FormattedTextToken`
into a tree (AST) of `FormattedTextASTNode`.

- warning: right now the AST is a linked list of `FormattedTextPartASTNode` but that may changes in the future.

For more information, read:
- http://craftinginterpreters.com/representing-code.html
- http://craftinginterpreters.com/parsing-expressions.html

Responsabilities:
- transform an array of `FormattedTextToken` into a Tree of FormattedTextASTNode
- add the right `text` value to `TextPart`
- apply the correct tag (eg: then tokens from the lexing of `A<b>B</b>C` would result of Node with `text` "A" and "C" to not have `.bold` tag  and "B" to have `.bold` tag)
- report error in a meaningful way (eg: `A<a>B</b>` or `<a>`) but not handle them (it is the Interpreter responsability)

Collaborators:
- consume an array of `FormattedTextToken`
- produce a tree `FormattedTextASTNode`
- throws `FormattedTextParser.Error`
*/

// MARK: - AST

/// Describe an AST Node
protocol FormattedTextASTNode {}

/**
Represents a part of the resulting UI Component, with the `text` value containing the string value
and some `FormattedTextTagType` (such as `.bold`) to condition the rendering.

- parameter text: the textual content of the text part, in form of a swift string
- parameter styles: a list of `FormattedTextStyle`

# Notes: #
1. The `next` property is necessary to form a linked list. It can be null an is thus optional.

*/
class TextPart: FormattedTextASTNode {
    /// Represents the textual content of the `TextPart`
    private(set) var text: String
    
    /// List the multiple `FormattedTextStyle` applied to the `TextPart`
    private(set) var styles: [FormattedTextStyle] = []
    
    // MARK: - Linked List
    
    private(set) var next: TextPart?
    
    // MARK: - Public API
    
    /// Creates a new `TextPart`
    init(text: String, styles: [FormattedTextStyle] = []) {
        self.text = text
        self.styles = styles
    }
    
    /// Creates / Extends a LinkedList by adding the next `TextPart` of the sibling text
    func addTextPart(node part: TextPart) {
        self.next = part
    }
}

// We need `TextPart` to inherit from `Equatable` for the XCTest
extension TextPart: Equatable {
    static func == (lhs: TextPart, rhs: TextPart) -> Bool {
        return lhs.styles == rhs.styles && lhs.text == rhs.text
    }
}

// MARK: - Parser

/// Given an array of `Token`,
/// computes a LinkedList of `MarkupTextPart`

/**
 Given an array of `FormattedTextToken`, compute an AST of `FormattedTextASTNode`
 
 - parameter tokens: An array of `FormattedTextToken` coming from the Lexer.
 - returns: an AST of `FormattedTextASTNode`
 - warning: Use Recursive decent parser and thus does not understand infix priority
 */
class FormattedTextParser {
    // MARK: - Input
    
    /// The only input is a array of `FormattedTextToken`, ordered as the initial rawText that was scanned by the lexer
    private var tokens: [FormattedTextToken]
    
    // MARK: - Offset
    
    /// Indicates up to which token the parser has parsed
    private var currentIndex = 0
    
    // MARK: - Context
    
    /// Represents the context of the parser
    private var styleContext: Stack<FormattedTextStyle> = Stack()
    
    // MARK: - Public API
    
    /// Initializes a parser with a text (Swift string, parsed as utf8)
    init(tokens: [FormattedTextToken]) {
        self.tokens = tokens
    }
    
    /// Parses an array of `FormattedTextToken` into an AST
    func parse() throws -> TextPart {
        // Step0: we need to handle the case where there is no token in case of an empty string
        guard !isAtEnd() else { throw Error.emptyInput }
        
        // Step1, Step2: Then, parse text parse recursivly
        let textPart = try parseInnerPart()
        
        // Step3: Ensure the styleContext array is empty (else it mean that some tag have not been closed)
        guard styleContext.count == 0 else {
            // NOT: Should never be reached as "parseOpeningTag/0" is throwing ".wrongClosingTag" at step 1.2.8.1
            throw Error.unexpected
        }
        
        // And return the resulting AST node
        return textPart
    }
    
    // MARK: - Core
    
    /// Recursivly parse inner part (a raw text or "<tag>text</tag>" group)
    private func parseInnerPart() throws -> TextPart {
        var textPart: TextPart!
        
        // Step1: try to parse ....
        if case .string = peek() { // ............... as a text (Step 1.1)
            textPart = try parseText()
            
        } else if case .openingTag = peek() { // .... or as a "<tag>text</tag>" group (Step 1.2)
            textPart = try parseOpeningTag()
            
        } else {
            // Edge case (Step 1.3): if node is not a text or a opening tag (eg if it is a closing tag (like "</b> text")) it is an error
            throw Error.unexpectedToken(token: peek())
        }
        
        // Step2: If there is more token, continue the parsing
        if !isAtEnd() {
            // Step2.1: Call itself recursivly
            let childTextPart = try parseInnerPart()
            
            // Step2.2: and set the child to construct the LinkedList
            textPart.addTextPart(node: childTextPart)
        }
        
        // And return the AST Node to "parse/0" for a final security check
        return textPart
    }
    
    /// Step 1.1: Parse raw text
    private func parseText() throws -> TextPart {        
        // Step 1.1.1: we "just" advance
        guard case let .string(value) = advance() else { throw Error.unexpected }
        
        // Step 1.1.2: and then we create a AST node of type "TextPart" with current styles
        return TextPart(text: value, styles: styleContext.toArray())
    }
    
    /// Step 1.2: Parse "<tag>text</tag>" group
    private func parseOpeningTag() throws -> TextPart {
        // Step 1.2.1: we start matching the opening tag
        let token = advance()
        guard case let .openingTag(openingStyle) = token  else {
            throw Error.unexpectedToken(token: token)
        }
        
        // Step 1.2.2: we verify that this style is not present in the styleContext ("<b><b>blabal..." is likely an error)
        if styleContext.contains(openingStyle) {
            throw Error.alreadyPresentTag(type: openingStyle)
        }
        
        // Step 1.2.3: we add the matched styled to the current styleContext
        styleContext.push(openingStyle)
        
        // Step 1.2.4: we verify that we are not at the end (we still need at least a .string and a .closingTag)
        guard !isAtEnd() else { throw Error.expectedText }
        
        // Step 1.2.5: (error niceties) to report the proper Error.emptyTag (and not generic Error.unexpectedToken) we check for a closing tag
        if case let .closingTag(closingStyle) = peek() {
            // Step 1.2.5.1: It is a Error.emptyTag only if the closing tag is the same style as the opening tag
            if closingStyle == openingStyle {
                throw Error.emptyTag(type: openingStyle)
            }
        }
        
        // Step 1.2.6: we parse the inner part (a raw text or another group)
        
        // TODO: this part is really similar to "parseInnerPart/0", except: 1. the handling of "unexpectedToken", 2. the recursion if not over
        // TODO: .... I think 2. is the right place to parse "<a>text<b>text</b></a> so we should maybe add it
        // TODO: .... but 1) makes less sense inside a already opened expression
        // TODO: .... we could think of a "reportWrongClosingTag/0" that throws "unexpectedToken" if the styleContext stack is empty ("</a> test") or "wrongClosingTag" if not ("<a>test</b>)
        // TODO: .... anyway there is room for brainstorming and refactoring here, esepecially once two or more tag are supported
        // TODO: ..... right now it works but this is more likely a coincidence ¯\_(ツ)_/¯
        
        var textPart: TextPart!
        
        if case .string = peek() {
            textPart = try parseText()
        } else if case .openingTag = peek() {
            textPart = try parseOpeningTag()
        }
        
        // Step 1.2.7: we verify that we are not at the end (we still need a .closingTag)
        guard !isAtEnd() else { throw Error.expectedClosingTag(type: openingStyle) }
        
        // Step 1.2.8: we match the closing tag
        guard case let .closingTag(closingStyle) = advance() else {
            // TODO: right now, the parser only parse "<b>test</b>".
            // TODO: .... it expect the format <tag1> then text then </tag1>
            // TODO: .... I'm pretty sure the existing code does not parse "<b>test<a>test</a></b>".
            // TODO: .... To be considered (and unit tested ^^) when evolving code to support multiple tag
            
            // Step 1.2.8.1: and report an error if there is no closing tag
            throw Error.expectedClosingTag(type: openingStyle)
        }
        
        // Step 1.2.9: and we expect it to be the same type as opening one ("<b></a>" is an error)
        if closingStyle != openingStyle {
            throw Error.wrongClosingTag(currentType: closingStyle, expectedType: openingStyle)
        }
        // Step 1.2.10: we then remove the tag from the modifier by poping the stack
        _ = styleContext.pop()
        
        // And return the AST Node to "parseInnerPart/0" that will recurse if we are not at the end
        return textPart
    }
    
    // MARK: - Helper functions
    
    /// Checks if we have parsed all tokens
    private func isAtEnd() -> Bool {
        return currentIndex == tokens.count
    }
    
    /// Looks at next token but don't consume it
    func peek() -> FormattedTextToken {
        return tokens[currentIndex]
    }
    
    /// Gets the token and consumes it by increasing the offset
    func advance() -> FormattedTextToken {
        let token = tokens[currentIndex]
        currentIndex += 1
        return token
    }

}

extension FormattedTextParser {
    enum Error: Swift.Error, Equatable {
        /// Should never happen. Mostly used in edge case that should be tested before, but the compiler is yelling at me.
        /// (example: "advance/0" inside "parseText/0" returns ".string(text)" but the compiler is not aware of this. We guard let to make the compiler happy)
        case unexpected
        /// Happens when we do "</a>test" : starting with a "closingTag" is by all mean unexpected and wrong
        case unexpectedToken(token: FormattedTextToken)
        /// Indicates that we expected an "openingTag". It was deprecated because the only part where it was use was more fitting `.unexpectedToken`
        @available(*, deprecated, message: ".unexpectedToken should be used")
        case expectedOpeningTag
        /// Indicates that we expected an "openingTag". It is used in "<a>test", and by coincidence will also be throw right now on "<b>" in "<a>test<b>test></b></a>"
        case expectedClosingTag(type: FormattedTextStyle)
        /// Indicates that we get an "closingTag" but the associated style is wrong. For instance "<a><b>Test</a></b>"
        case wrongClosingTag(currentType: FormattedTextStyle, expectedType: FormattedTextStyle)
        /// Indicates that tag is empty: "<a></a>"
        case emptyTag(type: FormattedTextStyle)
        /// Indicates that input is empty: ""
        case emptyInput
        /// Indicates the tag is not finished eg "test <a>". This is uncorrect, in the same veins than "expectedClosingTag" as "<a>" is uncorreect but the stuff after "<a>" could be another tag.
        case expectedText
        /// Indicates a repetion for instance "<a><b><a>text</a></b></a>" adds two times "a" style and that makes no sense
        case alreadyPresentTag(type: FormattedTextStyle)
    }
}
