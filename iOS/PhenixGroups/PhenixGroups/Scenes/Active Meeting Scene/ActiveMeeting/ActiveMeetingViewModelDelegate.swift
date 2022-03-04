//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixCore

protocol ActiveMeetingViewModelDelegate: AnyObject {
    typealias ViewModel = ActiveMeetingViewController.ViewModel

    func activeMeetingViewModel(_ viewModel: ViewModel, selfMemberDidChangeCameraState enabled: Bool)
    func activeMeetingViewModel(_ viewModel: ViewModel, selfMemberDidChangeMicrophoneState enabled: Bool)
    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChangeCameraState enabled: Bool)
    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChangeMicrophoneState enabled: Bool)
    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChange member: PhenixCore.Member)
}
