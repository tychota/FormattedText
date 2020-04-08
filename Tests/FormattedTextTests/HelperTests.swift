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
    
}
