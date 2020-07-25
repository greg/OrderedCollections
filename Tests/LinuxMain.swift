import XCTest

import RedBlackTreeTests

var tests = [XCTestCaseEntry]()
tests += RedBlackTreeTests.allTests()
tests += OrderedCollectionsTests.allTests()
XCTMain(tests)
