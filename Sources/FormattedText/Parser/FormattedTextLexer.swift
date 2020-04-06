// MARK: - Token

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
    case openingTag(type: FormattedTextTagType)
    /// Closing tag, eg: `</b>`
    case closingTag(type: FormattedTextTagType)
}


extension FormattedTextToken: Equatable {}

// MARK: - Lexer

class FormattedTextLexer {
    // MARK: -Input & Output
    
    /// input text, as a utf8 parsed string
    private var text: String
    /// results token
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
    
    /// We first init a parser with a text (Swift string, parsed as utf8)
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
    
    /// Scan one token, either a tag or by default a text
    private func scanToken() {
        // Step 1: Greb next char
        let char = advance()
        
        switch char {
            
        // Step 2a: If it is a "<"
        case "<":
            // Step 2a.1: Try matching an opening tag <x>
            if matchEndOfOpeningTag(value: "b") {
                tokens.append(.openingTag(type: .bold))
            
            // Step 2a.2: or try matching an closing tag </x>
            } else if matchEndOfClosingTag(value: "b") {
                tokens.append(.closingTag(type: .bold))
            
            // Step 2a.3: It is still possible that "<" matches nothing, in this case fallthrough
            } else {
                    fallthrough
            }
        default:
            // Step 2b.1: Advance current offset until we reach a tag or the end of the file
            while !checkTag() && !isAtEnd() {
                _ = advance()
            }
            // Step 2b.1: And extract the susbtring
            let value = text[startIndex ..< currentIndex]
            tokens.append(.string(value: value))
        }
    }
    
    // MARK: - Utility function
    
    /// Check if we have parse the full screen
    private func isAtEnd() -> Bool {
        return currentIndex >= text.count
    }
    
    /// Advance `current`  offset from `n` to `n+1` and return the char at `n`
    private func advance() -> String {
        currentIndex += 1
        return text[currentIndex - 1]
    }
    
    /// Look forward at the char at `n` without changing the offset
    private func peek() -> String {
        // If we are at end, return null bit
        guard !isAtEnd() else { return "\0" }
        return text[currentIndex]
    }
    
    /// Return the char at `n` without changing the offset
    private func peekNext(number: Int = 1) -> String {
        guard currentIndex + number <= text.count else { return "\0" }
        return text[currentIndex + number]
    }
    
    /// Check if next char is `expected`
    /// - if true, advance the `current` offset
    private func match(_ expected: String) -> Bool {
        guard !isAtEnd() else { return false }
        guard text[currentIndex] == expected else { return false }
        
        currentIndex += 1
        return true
    }
    
    // MARK: - Helper
    
    /// Peek (look forward but without any offset change) tag `<x>` or `</x>`
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
    
    /// Match `x>`, given the already matched `<`, where `x` is one of the tag name (`b`)
    private func matchEndOfOpeningTag(value: String) -> Bool {
        guard match(value) else { return false }
        guard match(">") else { return false }
        
        return true
    }
    
    /// Match `</x>`, given the already matched `<`, where `x` is one of the tag name (`b`)
    private func matchEndOfClosingTag(value: String) -> Bool {
        guard match("/") else { return false }
        guard match(value) else { return false }
        guard match(">") else { return false }
        
        return true
    }
}
