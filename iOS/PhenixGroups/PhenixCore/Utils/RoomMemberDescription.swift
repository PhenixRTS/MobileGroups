//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol RoomMemberDescription {
    var memberRepresentation: RoomMemberRepresentation? { get set }
}

extension RoomMemberDescription {
    var memberDescription: String { memberRepresentation?.identifier ?? "-" }
}
