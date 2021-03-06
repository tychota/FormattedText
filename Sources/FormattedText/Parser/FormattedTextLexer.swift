/**
 The purpose of the `FormattedTextLexer` is to transform an unparsed string (such as `toto<b>test</b>toto`)
 into a list of `FormattedTextToken` (such `[.text("toto"), .openingTag(.bold), .text("test"), .closingTag(.bold), .text("toto")]`
 
 It uses for this two offsets, as described in http://craftinginterpreters.com/image/scanning-on-demand/fields.png
 (from the awesome Crafting Interpreters online book: http://craftinginterpreters.com/)
 and iterativly convert the rawString into Tokens.
 
 For more information, read:
 - http://craftinginterpreters.com/scanning.html
 - http://craftinginterpreters.com/scanning-on-demand.html
 
 Responsabilities:
 - parse an utf8 encoded string into `FormattedTextToken` array
 - handle edge case like empty string, uncompleted tags (why couldn't a string be `"<b test"`)
 - but does not ensure coherance between tags (eg `"<a>test</b>"`): that is the parser responsability
 
 Collaborators:
 - consume a raw swift string
 - produce an array of `FormattedTextToken` that itself uses: 1) swift `String` (to represent text part) 2) `FormattedTextStyle` to represent the markup that needs to be applied to the text
 */


// MARK: - FormattedTextToken

/**
 Output of the Lexer
 
 # Eg: #
 1. a string (eg `"toto"`)
 2. an opening tag (eg `<b>`)
 3. an closing tag (eg `</b>`)
 
 */
enum FormattedTextToken {
    /// Raw string token, with a string value
    case string(value: String)
    /// Opening tag, eg: `<b>`
    case openingTag(type: FormattedTextStyle)
    /// Closing tag, eg: `</b>`
    case closingTag(type: FormattedTextStyle)
}


extension FormattedTextToken: Equatable {}

// MARK: - Lexer

/**
FormattedTextLexer transforms a raw text (UTF-8 string) into a list of `FormattedTextLexer`

- parameter text: the raw text thats needs to be formatted. This text (eg `<b>test</b>`) contains some text parts (eg `"test"`) and some tag (eg: `<b>` to open` or `</b>` to close)
- returns: an array of `FormattedTextToken`
- warning: so far the lexer did not throw (maybe in the future it will throw on unexpected character such as null byte `"\0"`). It expects the input string to be UTF-8.
*/
class FormattedTextLexer {
    // MARK: - Input & Output
    
    /// Input text, as a utf8 parsed string
    private var text: String
    /// Results token
    private var tokens: [FormattedTextToken] = []
    
    // MARKS: - Offsets
    
    // We also needs offsets to separate raw text in offset
    //
    // Eg
    // <b>Toto</b>
    //    ↑   ↑
    //   (s) (c)
    // Where (s) is the startIndex and (c) is the curentIndex
    
    /// Marks the beginng of the current Token being scanned
    private var startIndex = 0
    
    /// Points to the current character being scanned
    private var currentIndex = 0
    
    // MARK: - Public API
    
    /// Initilizes a Lexer with a text (Swift string, parsed as utf8)
    init(text: String) {
        self.text = text
    }
    
    /// Scan tokens iterativly and returns an array of tokens
    func scan() -> [FormattedTextToken] {
        //
        while !isAtEnd() {
            startIndex = currentIndex
            scanToken()
        }
        return tokens
    }
    
    // MARK: - private
    
    /// Scans one token, either a tag or by default a text
    private func scanToken() {
        // Step 1: Grabs next char
        let char = advance()
        
        switch char {
            
        // Step 2a: If it is a "<"
        case "<":
            // Step 2a.1: Tries matching an opening tag <x>
            if matchEndOfOpeningTag(value: "b") {
                tokens.append(.openingTag(type: .bold))
            
            // Step 2a.2: or tries matching an closing tag </x>
            } else if matchEndOfClosingTag(value: "b") {
                tokens.append(.closingTag(type: .bold))
            
            // Step 2a.3: It is still possible that "<" matches nothing, in this case fallthrough
            } else {
                    fallthrough
            }
        default:
            // Step 2b.1: Advances current offset until we reach a tag or the end of the file
            while !checkTag() && !isAtEnd() {
                _ = advance()
            }
            // Step 2b.1: And extracts the susbtring
            let value = text[startIndex ..< currentIndex]
            tokens.append(.string(value: value))
        }
    }
    
    // MARK: - Utility function
    
    /// Checks if we have parse the full screen
    private func isAtEnd() -> Bool {
        return currentIndex >= text.count
    }
    
    /// Advances `current`  offset from `n` to `n+1` and return the char at `n`
    private func advance() -> String {
        currentIndex += 1
        return text[currentIndex - 1]
    }
    
    /// Looks forward at the char at `n` without changing the offset
    private func peek() -> String {
        // If we are at end, return null bit
        guard !isAtEnd() else { return "\0" }
        return text[currentIndex]
    }
    
    /// Returns the char at `n` without changing the offset
    private func peekNext(number: Int = 1) -> String {
        guard currentIndex + number <= text.count else { return "\0" }
        return text[currentIndex + number]
    }
    
    /// Checks if next char is `expected`
    /// - if true, advance the `current` offset
    private func match(_ expected: String) -> Bool {
        guard !isAtEnd() else { return false }
        guard text[currentIndex] == expected else { return false }
        
        currentIndex += 1
        return true
    }
    
    // MARK: - Helper
    
    /// Peeks (looks forward but without any offset change) tag `<x>` or `</x>`
    private func checkTag() -> Bool {
        guard peek() == "<" else { return false }
        
        // Match closing tag
        if peekNext(number: 1) == "/" {
            guard peekNext(number: 2) == "b" else { return false }
            return peekNext(number: 3) == ">"
            
        // Match opening tag
        } else {
            guard peekNext(number: 1) == "b" else { return false }
            return peekNext(number: 2) == ">"
        }
    }
    
    /// Matches `x>`, given the already matched `<`, where `x` is one of the tag name (`b`)
    private func matchEndOfOpeningTag(value: String) -> Bool {
        guard match(value) else { return false }
        guard match(">") else { return false }
        
        return true
    }
    
    /// Matches `</x>`, given the already matched `<`, where `x` is one of the tag name (`b`)
    private func matchEndOfClosingTag(value: String) -> Bool {
        guard match("/") else { return false }
        guard match(value) else { return false }
        guard match(">") else { return false }
        
        return true
    }
}
