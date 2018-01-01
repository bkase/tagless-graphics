import XCTest
@testable import TaglessGraphics

class TaglessGraphicsTests: XCTestCase {
    func testExample() {
        print("@ 40")
        print(
            pretty(sample()).renderPretty(ribbonFrac: 0.4, pageWidth: 40).displayString()
        )

        print("@ 80")
        print(
            pretty(sample()).renderPrettyDefault().displayString()
        )
        
        print("@ 120")
        print(
            pretty(sample()).renderPretty(ribbonFrac: 0.4, pageWidth: 120).displayString()
        )
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
