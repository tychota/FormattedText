extension String {
    var length: Int {
        return count
    }
    
    subscript(index: Int) -> String {
        return self[index ..< index + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript(range: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, range.lowerBound)),
                                            upper: min(length, max(0, range.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
