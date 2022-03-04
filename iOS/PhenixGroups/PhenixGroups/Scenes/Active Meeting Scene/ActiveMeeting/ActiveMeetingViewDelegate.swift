//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol ActiveMeetingViewDelegate: AnyObject {
    func activeMeetingView(_ view: ActiveMeetingView, didChangeCameraState enabled: Bool)
    func activeMeetingView(_ view: ActiveMeetingView, didChangeMicrophoneState enabled: Bool)
    func activeMeetingView(_ view: ActiveMeetingView, didScrollTillSectionWithIndex index: Int)
    func activeMeetingViewDidTapMenuButton(_ view: ActiveMeetingView)
    func activeMeetingViewDidTapLeaveMeetingButton(_ view: ActiveMeetingView)
}
