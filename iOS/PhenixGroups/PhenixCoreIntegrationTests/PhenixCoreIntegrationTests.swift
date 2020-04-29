//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

@testable
import PhenixCore
import XCTest

class PhenixCoreIntegrationTests: XCTestCase {
    let url = URL(string: "https://demo.phenixrts.com/pcast")!

    func testCreateAndJoinRoom() {
        // Given
        let expectation1 = expectation(description: "Room created")
        let expectation2 = expectation(description: "Joined the room")

        let alias = "Testing"
        let displayName = "Test User"

        let phenixManager = PhenixManager(backend: url, privateQueue: .main)
        phenixManager.start(unrecoverableErrorCompletion: nil)

        // When
        phenixManager.createRoom(withAlias: alias) { result in
            if case let Result.success(room) = result {
                expectation1.fulfill()

                phenixManager.joinRoom(with: .identifier(room.getId()), displayName: displayName) { error in
                    if error == nil {
                        expectation2.fulfill()
                    }
                }
            }
        }

        // Then
        waitForExpectations(timeout: 5.0)
    }
}
