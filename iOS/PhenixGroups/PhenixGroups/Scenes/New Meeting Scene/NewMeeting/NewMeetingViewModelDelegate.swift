//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol NewMeetingViewModelDelegate: AnyObject {
    func newMeetingViewModel(_ view: NewMeetingViewController.ViewModel, willJoinMeeting meetingCode: String)
    func newMeetingViewModel(_ view: NewMeetingViewController.ViewModel, didJoinMeeting meetingCode: String)
    func newMeetingViewModel(_ view: NewMeetingViewController.ViewModel, didFailToJoinMeetingWith description: String?)
    func newMeetingViewModelWillSetupLocalMedia(_ view: NewMeetingViewController.ViewModel)
    func newMeetingViewModelDidSetupLocalMedia(_ view: NewMeetingViewController.ViewModel)
    func newMeetingViewModelDidFailToSetupLocalMedia(_ view: NewMeetingViewController.ViewModel)
}
