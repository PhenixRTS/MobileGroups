//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol JoinMeetingViewModelDelegate: AnyObject {
    func joinMeetingViewModel(_ view: JoinMeetingViewController.ViewModel, willJoinMeeting meetingCode: String)
    func joinMeetingViewModel(_ view: JoinMeetingViewController.ViewModel, didJoinMeeting meetingCode: String)
    func joinMeetingViewModel(
        _ view: JoinMeetingViewController.ViewModel,
        didFailToJoinMeetingWith description: String?
    )
}
