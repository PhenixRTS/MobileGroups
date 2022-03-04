//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension ActiveMeetingViewController {
    class ViewModel {
        private let core: PhenixCore
        private let session: AppSession
        private let preferences: Preferences

        private var currentlyFocusedMember: PhenixCore.Member?

        private var selectedMemberChangedSubject = PassthroughSubject<Void, Never>()
        private lazy var selectedMemberPublisher: AnyPublisher<PhenixCore.Member?, Never> = {
            selectedMemberChangedSubject
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .map { [weak self] _ in
                    self?.core.members.first(where: \.isSelected)
                }
                .eraseToAnyPublisher()
        }()

        private lazy var loudestMemberPublisher: AnyPublisher<PhenixCore.Member, Never> = {
            Timer.publish(every: 1, tolerance: 0.2, on: RunLoop.main, in: .common)
                .autoconnect()
                .compactMap { [weak self] _ in
                    self?.core.members
                        .filter { $0.connectionState == .active }
                        .max { $0.volume > $1.volume }
                }
                .removeDuplicates()
                .eraseToAnyPublisher()
        }()

        private var selectedMemberCancellable: AnyCancellable?
        private var loudestMemberCancellable: AnyCancellable?

        private var selectionMemberCancellables = Set<AnyCancellable>()
        private var memberListChangeCancellable: AnyCancellable?

        private var selfMemberAudioCancellable: AnyCancellable?
        private var selfMemberVideoCancellable: AnyCancellable?

        private var focusMemberAudioCancellable: AnyCancellable?
        private var focusMemberVideoCancellable: AnyCancellable?

        lazy var meetingCode: String = {
            guard let meetingCode = preferences.currentMeetingCode else {
                fatalError("Meeting code is required to be provided.")
            }
            return meetingCode
        }()

        var displayName: String { preferences.displayName }
        var isCameraEnabled: Bool { preferences.isCameraEnabled }
        var isMicrophoneEnabled: Bool { preferences.isMicrophoneEnabled }

        weak var delegate: ActiveMeetingViewModelDelegate?

        init(core: PhenixCore, session: AppSession, preferences: Preferences) {
            self.core = core
            self.session = session
            self.preferences = preferences
        }

        func subscribeForEvents() {
            subscribeForMemberListChangeEvents()
        }

        func setMicrophone(enabled: Bool) {
            preferences.isMicrophoneEnabled = enabled
            core.setSelfAudioEnabled(enabled: enabled)
        }

        func setCamera(enabled: Bool) {
            preferences.isCameraEnabled = enabled
            core.setSelfVideoEnabled(enabled: enabled)
        }

        func flipCamera() {
            core.flipCamera()
        }

        func leaveMeeting() {
            core.leave(alias: meetingCode)
        }

        func focus(_ member: PhenixCore.Member, on layer: CALayer) {
            guard member != currentlyFocusedMember else {
                return
            }

            subscribeForMemberMediaEvents(focusedMember: member)

            if let previousMember = currentlyFocusedMember {
                // Un-focus previous member.
                if previousMember.isSelf {
                    core.previewVideo(layer: nil)
                } else {
                    core.renderVideo(alias: previousMember.id, layer: nil)
                }
            }

            currentlyFocusedMember = member

            // Set focus on the new member.
            if member.isSelf {
                core.previewVideo(layer: layer)
            } else {
                core.renderVideo(alias: member.id, layer: layer)
            }
        }

        // MARK: - Private methods

        private func subscribeForSelfMemberMediaStateChanges() {
            guard let member = core.members.selfMember() else {
                return
            }

            subscribeForMemberAudioEvents(selfMember: member)
            subscribeForMemberVideoEvents(selfMember: member)
        }

        private func subscribeForMemberMediaEvents(focusedMember member: PhenixCore.Member) {
            subscribeForMemberAudioEvents(focusMember: member)
            subscribeForMemberVideoEvents(focusMember: member)
        }

        private func subscribeForMemberListChangeEvents() {
            memberListChangeCancellable = core.membersPublisher
                .sink { [weak self] members in
                    guard let self = self else {
                        return
                    }

                    self.currentlyFocusedMember = nil
                    self.selectionMemberCancellables.removeAll()

                    self.subscribeForSelfMemberMediaStateChanges()
                    self.subscribeForLoudestMember()
                    self.subscribeForSelectedMemberChangeEvents()

                    members.forEach(self.subscribeForMemberSelectionEvents)
                }
        }

        private func subscribeForSelectedMemberChangeEvents() {
            selectedMemberCancellable = selectedMemberPublisher
                .sink { [weak self] member in
                    guard let self = self else { return }

                    if let member = member {
                        // A member is explicitly selected (pinned) by the current device user.
                        self.loudestMemberCancellable = nil
                        self.delegate?.activeMeetingViewModel(self, focusMemberDidChange: member)
                    } else {
                        // No member is explicitly selected, set focus in the main view on the loudest member.
                        self.subscribeForLoudestMember()
                    }
                }
        }

        private func subscribeForLoudestMember() {
            loudestMemberCancellable = loudestMemberPublisher
                .sink { [weak self] loudestMember in
                    guard let self = self else { return }
                    self.delegate?.activeMeetingViewModel(self, focusMemberDidChange: loudestMember)
                }
        }

        private func subscribeForMemberAudioEvents(selfMember member: PhenixCore.Member) {
            selfMemberAudioCancellable = member.isAudioEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.preferences.isMicrophoneEnabled = enabled
                    self.delegate?.activeMeetingViewModel(self, selfMemberDidChangeMicrophoneState: enabled)
                }
        }

        private func subscribeForMemberVideoEvents(selfMember member: PhenixCore.Member) {
            selfMemberVideoCancellable = member.isVideoEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.preferences.isCameraEnabled = enabled
                    self.delegate?.activeMeetingViewModel(self, selfMemberDidChangeCameraState: enabled)
                }
        }

        private func subscribeForMemberAudioEvents(focusMember member: PhenixCore.Member) {
            focusMemberAudioCancellable = member.isAudioEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.activeMeetingViewModel(self, focusMemberDidChangeMicrophoneState: enabled)
                }
        }

        private func subscribeForMemberVideoEvents(focusMember member: PhenixCore.Member) {
            focusMemberVideoCancellable = member.isVideoEnabledPublisher
                .sink { [weak self] enabled in
                    guard let self = self else {
                        return
                    }

                    self.delegate?.activeMeetingViewModel(self, focusMemberDidChangeCameraState: enabled)
                }
        }

        private func subscribeForMemberSelectionEvents(_ member: PhenixCore.Member) {
            member.isSelectedPublisher
                .sink { [weak self] _ in
                    self?.selectedMemberChangedSubject.send()
                }
                .store(in: &selectionMemberCancellables)
        }
    }
}
