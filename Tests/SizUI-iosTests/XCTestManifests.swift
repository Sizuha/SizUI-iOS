import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SizUI_iosTests.allTests),
    ]
}
#endif
