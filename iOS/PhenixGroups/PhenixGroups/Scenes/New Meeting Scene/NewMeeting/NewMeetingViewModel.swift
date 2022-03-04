//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension NewMeetingViewController {
    class ViewModel {
        private let core: PhenixCore
        private let session: AppSession
        private let preferences: Preferences

        private var cancellable: AnyCancellable?
        private var lastConfiguration: PhenixCore.Room.Configuration?
        private var isMediaInitialized = false

        var initialMeetingCode: String?
        var displayName: String {
            get { preferences.displayName }
            set { preferences.displayName = newValue }
        }

        var isCameraEnabled: Bool { preferences.isCameraEnabled }
        var isMicrophoneEnabled: Bool { preferences.isMicrophoneEnabled }

        weak var delegate: NewMeetingViewModelDelegate?

        init(core: PhenixCore, session: AppSession, preferences: Preferences) {
            self.core = core
            self.session = session
            self.preferences = preferences
        }

        func setupLocalMediaIfNeeded() {
            if isMediaInitialized == false {
                core.setLocalMedia(enabled: true)
            }
        }

        func preview(on layer: CALayer) {
            if isMediaInitialized == true {
                core.previewVideo(layer: layer)
            }
        }

        func setMicrophone(enabled: Bool) {
            preferences.isMicrophoneEnabled = enabled
            core.setSelfAudioEnabled(enabled: enabled)
        }

        func setCamera(enabled: Bool) {
            preferences.isCameraEnabled = enabled
            core.setSelfVideoEnabled(enabled: enabled)
        }

        func joinMeetingIfNecessary() {
            guard let meetingCode = initialMeetingCode else {
                return
            }

            join(meetingCode: meetingCode)
            initialMeetingCode = nil
        }

        func join(meetingCode: String) {
            delegate?.newMeetingViewModel(self, willJoinMeeting: meetingCode)

            let configuration = PhenixCore.Room.Configuration(
                alias: meetingCode,
                publishToken: session.publishToken,
                audioStreamToken: session.audioStreamToken,
                videoStreamToken: session.videoStreamToken,
                memberName: displayName,
                memberRole: .audience,
                maxVideoSubscriptions: session.configuration.maxVideoSubscriptions,
                roomType: .multiPartyChat
            )

            lastConfiguration = configuration
            core.createRoom(configuration: configuration)
        }

        func flipCamera() {
            core.flipCamera()
        }

        func subscribeForEvents() {
            cancellable = core.eventPublisher
                .sink { [weak self] completion in
                    self?.processEventCompletion(completion)
                } receiveValue: { [weak self] event in
                    self?.processEvent(event)
                }
        }

        func unsubscribeFromEvents() {
            cancellable = nil
        }

        private func processEventCompletion(_ completion: Subscribers.Completion<PhenixCore.Error>) {
            // Do nothing specific. Bootstrap already handles these error cases.
            delegate?.newMeetingViewModel(self, didFailToJoinMeetingWith: nil)
        }

        // swiftlint:disable:next cyclomatic_complexity
        private func processEvent(_ event: PhenixCore.Event) {
            switch event {
            case .media(.mediaInitializing):
                delegate?.newMeetingViewModelWillSetupLocalMedia(self)

            case .media(.mediaInitialized):
                isMediaInitialized = true
                delegate?.newMeetingViewModelDidSetupLocalMedia(self)

            case .media(.mediaNotInitialized):
                delegate?.newMeetingViewModelDidFailToSetupLocalMedia(self)

            case .room(.roomCreated):
                guard let configuration = lastConfiguration else {
                    let reason = "Can't create the meeting. Configuration issue."
                    delegate?.newMeetingViewModel(self, didFailToJoinMeetingWith: reason)
                    return
                }

                core.joinToRoom(configuration: configuration)

            case .room(.roomJoined):
                guard var configuration = lastConfiguration else {
                    let reason = "Can't join the meeting. Configuration issue."
                    delegate?.newMeetingViewModel(self, didFailToJoinMeetingWith: reason)
                    return
                }

                configuration.memberRole = .moderator
                core.publishToRoom(configuration: configuration)

            case .room(.roomPublished):
                guard let configuration = lastConfiguration else {
                    let reason = "Can't publish to the meeting. Configuration issue."
                    delegate?.newMeetingViewModel(self, didFailToJoinMeetingWith: reason)
                    return
                }

                preferences.currentMeetingCode = configuration.alias
                delegate?.newMeetingViewModel(self, didJoinMeeting: configuration.alias)

            case .room(.roomCreationFailed(_, let error)),
                    .room(.roomJoiningFailed(_, let error)),
                    .room(.roomPublishingFailed(_, let error)):
                delegate?.newMeetingViewModel(self, didFailToJoinMeetingWith: error.localizedDescription)

            default:
                // do nothing, no other events needs to be processed here.
                break
            }
        }
    }
}
