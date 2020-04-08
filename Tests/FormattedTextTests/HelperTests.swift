import XCTest
@testable import FormattedText


class HelperTests: XCTestCase {
    func testStringSubscriptSimple() {
        // given
        let string = "abcdef"
        
        // when 1
        let substring1 = string[1 ... 3]
        // then 1
        XCTAssertEqual(substring1, "bcd")

        // when 2
        let substring2 = string[1 ..< 10]
        // then 2
        XCTAssertEqual(substring2, "bcdef")
        
        // when 3
        let substring3 = string[3]
        // then 3
        XCTAssertEqual(substring3, "d")
        
        // when 4
        let substring4 = string[7]
        // then 4
        XCTAssertEqual(substring4, "")
    }
    
    func testStringSubscriptUnicode() {
        // given
        let string = "Dog‼🐶"
        
        // when 1
        let substring1 = string[0 ... 2]
        // then 1
        XCTAssertEqual(substring1, "Dog")
        
        // when 2
        let substring2 = string[3 ..< 4 ]
        // then 2
        XCTAssertEqual(substring2, "‼")
        
        // when 3
        let substring3 = string[4]
        // then 3
        XCTAssertEqual(substring3, "🐶")
        
        // when 4
        let substring4 = string[7]
        // then 4
        XCTAssertEqual(substring4, "")
    }
    
    func testStack() {
        // given
        var stack = Stack<Int>()
        
        // when 1
        stack.push(1)
        stack.push(2)
        let pop1 = stack.pop()
        // then 1
        XCTAssertEqual(pop1, 2)
        
        // when 2
        let peek1 = stack.peek()
        // then 2
        XCTAssertEqual(peek1, 1)
        
        // when 3
        stack.push(3)
        let content = stack.toArray()
        // then 3
        XCTAssertEqual(content, [3, 1])
        
        // when 4
        let count = stack.count
        // then 4
        XCTAssertEqual(count, 2)
        
        // when 5
        let isEmpty = stack.isEmpty()
        // then 5
        XCTAssertEqual(isEmpty, false)
        
        // when 6
        let contains1 = stack.contains(2)
        let contains2 = stack.contains(3)
        // then 6
        XCTAssertEqual(contains1, false)
        XCTAssertEqual(contains2, true)
    }
}
