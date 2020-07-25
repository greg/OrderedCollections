import XCTest
@testable import RedBlackTree
import TestValues

final class RedBlackTreeTests: XCTestCase {
    
    func testTree() {
        var nums = insertNumbers
        var t = RedBlackTree<Int, ()>()
        XCTAssert(t.first == nil)
        XCTAssertEqual(t.startIndex, t.endIndex)
        for i in nums {
            t.insert(i, with: ())
        }
        nums.sort()

        XCTAssert(t.map({ $0.0 }).elementsEqual(nums))
        XCTAssertEqual(t[t.find(3)!].0, 3)
        XCTAssertEqual(t.find(-1), nil)
        XCTAssertEqual(t[t.lowerBound(-5)].0, 0)
        XCTAssertEqual(t[t.lowerBound(32)].0, nums[nums.firstIndex(where: { $0 >= 32 })!])
        XCTAssertEqual(t[t.upperBound(3)].0, nums[nums.firstIndex(where: { $0 > 3 })!])
        XCTAssertEqual(t[t.upperBound(73)].0, nums[nums.firstIndex(where: { $0 > 73 })!])
        XCTAssertEqual(t.upperBound(100), t.endIndex)
        XCTAssertEqual(t.lowerBound(101), t.endIndex)
        XCTAssertEqual(t.minKey, 0)
        XCTAssertEqual(t.maxKey, 100)

        for _ in 0..<300 {
            t.remove(at: t.endIndex.predecessor())
        }

        for n in nums[700..<1000] {
            t.insert(n, with: ())
        }

        XCTAssert(nums.elementsEqual(t.map { $0.0 }))

        for i in removeIndices {
            let it = t.find(nums[i])!
            XCTAssertEqual(t[it].0, nums[i])
            t.remove(at: it)
            nums.remove(at: i)
            XCTAssertEqual(t.count, nums.count)
            XCTAssertEqual(t.last?.0, nums.last)
            XCTAssertEqual(t.first?.0, nums.first)
            XCTAssert(t.map({ $0.0 }).elementsEqual(nums))
        }
    }
    
    func testDuplicateInsert() {
        let t: RedBlackTree = [(3, 1), (3, 3), (3, 2), (3, 5), (3, 7), (3, -1)]
        XCTAssertEqual(Array(t).map(\.value), [1, 3, 2, 5, 7, -1])
    }

    func testIndexing() {
        var a = RedBlackTree<Int, ()>([1, 2, 3, 4, 5].map { ($0, ()) })
        let i = a.find(3)!, j = a.find(2)!, k = a.find(5)!
        a.remove(at: i)
        XCTAssertEqual(a[j].0, 2)
        XCTAssertEqual(a[k].0, 5)
        var b = a
        XCTAssertEqual(b[j].0, 2)
        XCTAssertEqual(b[k].0, 5)
        b.remove(at: j)
        XCTAssert(b.elementsEqual([1, 4, 5].map { ($0, ()) }, by: { $0.0 == $1.0 }))
    }
}
