//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol NewMeetingControlViewDelegate: AnyObject {
    func newMeetingControlViewDidTapNewMeetingButton(_ view: NewMeetingControlView)
    func newMeetingControlViewDidTapJoinMeetingButton(_ view: NewMeetingControlView)
    func newMeetingControlView(_ view: NewMeetingControlView, didChangeDisplayName displayName: String)
}
