//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension ActiveMeetingMemberListTableViewCell {
    class ViewModel {
        private let core: PhenixCore
        private let member: PhenixCore.Member

        private var cancellables: Set<AnyCancellable> = []
        /// Boolean indicating that the current user is selected (pinned) currently.
        private var isSelected: Bool { member.isSelected }

        var displayName: String { member.name }
        var isAudioEnabled: Bool { member.isAudioEnabled }

        var showsCamera: Bool {
            isSelected == false && member.isVideoEnabled
        }

        weak var delegate: ActiveMeetingMemberListTableViewCellModelDelegate?

        init(core: PhenixCore, member: PhenixCore.Member) {
            self.core = core
            self.member = member
        }

        func renderPreviewIfNeeded(on layer: CALayer) {
            if member.isSelf {
                core.previewThumbnailVideo(layer: showsCamera ? layer : nil)
            } else {
                core.renderThumbnailVideo(alias: member.id, layer: showsCamera ? layer : nil)
            }
        }

        func convert(_ volume: PhenixCore.Member.Volume) -> AudioLevelView.Level {
            switch volume {
            case .volume0, .volume1, .volume2:
                return .low
            case .volume3, .volume4, .volume5, .volume6:
                return .medium
            case .volume7, .volume8, .volume9:
                return .high
            }
        }

        /// Subscribe for all member events which are represented in the user interface.
        ///
        /// It's better to call this method after setting the delegate instance.
        func subscribeForEvents() {
            cancellables.removeAll()

            subscribeToAudioEvents()
            subscribeToVideoEvents()
            subscribeToSelectionEvents()
            subscribeToConnectionEvents()
        }

        private func subscribeToAudioEvents() {
            member.isAudioEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.viewModel(self, didChangeAudioState: enabled)
                }
                .store(in: &cancellables)

            member.volumePublisher
                .compactMap { [weak self] volume in
                    self?.convert(volume)
                }
                .sink { [weak self] level in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.viewModel(self, didChangeVolume: level)
                }
                .store(in: &cancellables)
        }

        private func subscribeToVideoEvents() {
            member.isVideoEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.viewModel(self, didChangeVideoState: enabled)
                }
                .store(in: &cancellables)
        }

        private func subscribeToConnectionEvents() {
            member.connectionStatePublisher
                .sink { [weak self] state in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.viewModel(self, didChangeConnectionState: state)
                }
                .store(in: &cancellables)
        }

        private func subscribeToSelectionEvents() {
            member.isSelectedPublisher
                .sink { [weak self] isSelected in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.viewModel(self, didChangeSelectionState: isSelected)
                }
                .store(in: &cancellables)
        }
    }
}
