//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixCore

protocol ActiveMeetingMemberListTableViewCellModelDelegate: AnyObject {
    typealias ViewModel = ActiveMeetingMemberListTableViewCell.ViewModel

    func viewModel(_ viewModel: ViewModel, didChangeAudioState enabled: Bool)
    func viewModel(_ viewModel: ViewModel, didChangeVideoState enabled: Bool)
    func viewModel(_ viewModel: ViewModel, didChangeConnectionState state: PhenixCore.Member.ConnectionState)
    func viewModel(_ viewModel: ViewModel, didChangeSelectionState isSelected: Bool)
    func viewModel(_ viewModel: ViewModel, didChangeVolume level: AudioLevelView.Level)
}
