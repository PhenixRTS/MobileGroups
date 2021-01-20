//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

@testable
import PhenixCore
import XCTest

class RoomAliasTests: XCTestCase {
    func testGeneratedAliasIsRandom() {
        // When
        let alias1 = String.randomRoomAlias
        let alias2 = String.randomRoomAlias

        // Then
        XCTAssertNotEqual(alias1, alias2)
    }

    func testAliasPattern() {
        // Given
        let regex = try! NSRegularExpression(pattern: "^[a-z]{3}-[a-z]{4}-[a-z]{3}$")
        // When
        let alias: String = .randomRoomAlias

        // Then
        XCTAssertMatch(alias, regex)
    }
}

fileprivate extension XCTestCase {
    func XCTAssertMatch(_ string: String, _ regex: NSRegularExpression, file: StaticString = #file, line: UInt = #line) {
        let range = NSRange(location: 0, length: string.utf16.count) // Uses the utf16 count to avoid problems with emoji and similar.
        XCTAssertNotNil(regex.firstMatch(in: string, options: [], range: range), "\(string) does not matches \(regex.pattern)", file: file, line: line)
    }
}
