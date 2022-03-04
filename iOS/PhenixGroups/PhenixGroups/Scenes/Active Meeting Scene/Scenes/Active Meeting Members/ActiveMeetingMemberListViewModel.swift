//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension ActiveMeetingMemberListViewController {
    class ViewModel {
        private let core: PhenixCore
        private let session: AppSession

        private var selectedMember: PhenixCore.Member?

        let membersPublisher: AnyPublisher<[PhenixCore.Member], Never>

        init(core: PhenixCore, session: AppSession) {
            self.core = core
            self.session = session

            self.membersPublisher = core.membersPublisher
                .map { members in
                    members
                        // Filter out only the members with `active` or `away` connection state.
                        .filter { $0.isConnected }
                        // Sort by the user's activity.
                        .sorted { $0.lastUpdate > $1.lastUpdate }
                        // Sort them so that the self-member would always appear first in the list.
                        .sorted { $0.isSelf == true && $1.isSelf == false }
                }
                .eraseToAnyPublisher()
        }

        func subscribeToMembers() {
            core.subscribeToRoomMembers()
        }

        func select(_ member: PhenixCore.Member) {
            if let previouslySelectedMember = selectedMember {
                core.selectMember(previouslySelectedMember.id, isSelected: false)
            }

            selectedMember = member
            core.selectMember(member.id, isSelected: true)
        }

        func deselect(_ member: PhenixCore.Member) {
            selectedMember = nil
            core.selectMember(member.id, isSelected: false)
        }
    }
}
