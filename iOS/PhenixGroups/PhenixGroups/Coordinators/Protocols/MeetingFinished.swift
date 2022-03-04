//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol MeetingFinished: AnyObject {
    func meetingFinished(_ meeting: Meeting, withReason reason: (title: String, message: String?)?)
}
