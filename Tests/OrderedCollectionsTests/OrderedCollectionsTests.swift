import XCTest
@testable import OrderedCollections
import TestValues

final class OrderedCollectionsTests: XCTestCase {
    
    func testOrderedDictionary() {
        var a: OrderedDictionary = [5: "hello", 6: "aoeu", -1: ""]
        XCTAssertEqual(a[5], "hello")
        XCTAssertEqual(a[6], "aoeu")
        XCTAssertEqual(a[-1], "")
        a[2] = "htns"
        XCTAssertEqual(a[2], "htns")
        a[5] = "bye"
        XCTAssertEqual(a[5], "bye")
        a[6] = nil
        XCTAssertEqual(a.count, 3)
    }
}
