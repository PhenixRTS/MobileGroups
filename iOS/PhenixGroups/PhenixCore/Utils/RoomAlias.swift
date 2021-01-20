//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public extension String {
    static var randomRoomAlias: String {
        let symbols = "abcdefghijklmnopqrstuvwxyz"

        let firstPart = symbols.randomElements(3)
        let secondPart = symbols.randomElements(4)
        let thirdPart = symbols.randomElements(3)

        return "\(firstPart)-\(secondPart)-\(thirdPart)"
    }

    func randomElements(_ maxLength: Int) -> String {
        guard self.isEmpty == false else {
            return ""
        }

        var string = ""

        for _ in 0..<maxLength {
            // swiftlint:disable force_unwrapping
            string += String(self.randomElement()!)
        }

        return string
    }
}
