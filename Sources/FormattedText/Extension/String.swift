/**
 This String extension allows easier subscript.
 
 See: https://stackoverflow.com/questions/45497705/subscript-is-unavailable-cannot-subscript-string-with-a-countableclosedrange
 and: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html
 for more reasonnings.
 
 */


extension String {
    /// Extract the character at index
    subscript(index: Int) -> String {
        return self[index ..< index + 1]
    }
    
    /// Computes the substring of a closed range eg: `"abc"[0..<2]`
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: lower(bounds))
        let end = index(startIndex, offsetBy: upper(bounds))
        return String(self[start...end])
    }
    
    /// Computes the substring of a open range eg: `"abc"[1...2]`
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: lower(bounds))
        let end = index(startIndex, offsetBy: upper(bounds))
        return String(self[start..<end])
    }
    
    // MARK: - Private
    
    /// Compute the safe (within [0, length(string]] lower bound of a Range
    private func lower(_ bounds: Range<Int>) -> Int {
        return max(0, min(count, bounds.lowerBound))
    }
    /// Compute the safe (within [0, length(string]] lower bound of a closed Range
    private func lower(_ bounds: ClosedRange<Int>) -> Int {
        return max(0, min(count, bounds.lowerBound))
    }
    /// Compute the safe (within [0, length(string]] upper bound of a Range
    private func upper(_ bounds: Range<Int>) -> Int {
        return min(count, max(0, bounds.upperBound))
    }
    /// Compute the safe (within [0, length(string]] upper bound of a closed Range
    private func upper(_ bounds: ClosedRange<Int>) -> Int {
        return min(count, max(0, bounds.upperBound))
    }
}
