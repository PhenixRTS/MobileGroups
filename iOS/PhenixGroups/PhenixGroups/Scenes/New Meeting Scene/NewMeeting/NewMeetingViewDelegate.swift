//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol NewMeetingViewDelegate: AnyObject {
    func newMeetingView(_ view: NewMeetingView, didChangeCameraState enabled: Bool)
    func newMeetingView(_ view: NewMeetingView, didChangeMicrophoneState enabled: Bool)
    func newMeetingView(_ view: NewMeetingView, didChangeDisplayName displayName: String)
    func newMeetingViewDidTapMenuButton(_ view: NewMeetingView)
    func newMeetingViewDidTapNewMeetingButton(_ view: NewMeetingView)
    func newMeetingViewDidTapJoinMeetingButton(_ view: NewMeetingView)
}
