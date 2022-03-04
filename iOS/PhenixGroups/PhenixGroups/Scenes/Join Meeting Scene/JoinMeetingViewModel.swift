//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension JoinMeetingViewController {
    class ViewModel {
        private let core: PhenixCore
        private let session: AppSession
        private let preferences: Preferences

        private var cancellables = Set<AnyCancellable>()
        private var lastConfiguration: PhenixCore.Room.Configuration?

        weak var delegate: JoinMeetingViewModelDelegate?

        init(core: PhenixCore, session: AppSession, preferences: Preferences) {
            self.core = core
            self.session = session
            self.preferences = preferences
        }

        func join(meetingCode: String) {
            delegate?.joinMeetingViewModel(self, willJoinMeeting: meetingCode)

            let configuration = PhenixCore.Room.Configuration(
                alias: meetingCode,
                publishToken: session.publishToken,
                audioStreamToken: session.audioStreamToken,
                videoStreamToken: session.videoStreamToken,
                memberName: preferences.displayName,
                memberRole: .audience,
                maxVideoSubscriptions: session.configuration.maxVideoSubscriptions
            )

            lastConfiguration = configuration
            core.joinToRoom(configuration: configuration)
        }

        func subscribeToEvents() {
            core.eventPublisher
                .sink { [weak self] completion in
                    self?.processEventCompletion(completion)
                } receiveValue: { [weak self] event in
                    self?.processEvent(event)
                }
                .store(in: &cancellables)
        }

        private func processEventCompletion(_ completion: Subscribers.Completion<PhenixCore.Error>) {
            // Do nothing specific. Bootstrap already handles these error cases.
            delegate?.joinMeetingViewModel(self, didFailToJoinMeetingWith: nil)
        }

        private func processEvent(_ event: PhenixCore.Event) {
            switch event {
            case .room(.roomJoined):
                guard var configuration = lastConfiguration else {
                    let reason = "Can't join the meeting. Configuration issue."
                    delegate?.joinMeetingViewModel(self, didFailToJoinMeetingWith: reason)
                    return
                }

                configuration.memberRole = .moderator
                core.publishToRoom(configuration: configuration)

            case .room(.roomPublished):
                guard let configuration = lastConfiguration else {
                    let reason = "Can't publish to the meeting. Configuration issue."
                    delegate?.joinMeetingViewModel(self, didFailToJoinMeetingWith: reason)
                    return
                }

                preferences.currentMeetingCode = configuration.alias
                delegate?.joinMeetingViewModel(self, didJoinMeeting: configuration.alias)

            case .room(.roomJoiningFailed(_, let error)),
                    .room(.roomPublishingFailed(_, let error)):
                delegate?.joinMeetingViewModel(self, didFailToJoinMeetingWith: error.localizedDescription)

            default:
                // do nothing, no other events needs to be processed here.
                break
            }
        }
    }
}
