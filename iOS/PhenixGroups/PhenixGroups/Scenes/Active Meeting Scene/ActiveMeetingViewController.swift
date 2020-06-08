//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    private var pageController: UIPageViewController!
    /// Page sub-controllers, like *Member List Controller*, *Information Controller*, *Chat Controller*, displayed by a `UIPageViewController`
    private var controllers = [UIViewController]()
    private var membersListViewController: ActiveMeetingMemberListViewController!

    weak var coordinator: MeetingFinished?
    weak var media: UserMediaStreamController?

    var displayName: String!
    var joinedRoom: JoinedRoom!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(joinedRoom != nil, "Joined meeting instance is necessary")
        assert(displayName != nil, "Display name is necessary")

        configure()

        joinedRoom.subscribeToMemberList(membersListViewController)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }

    func leave() {
        os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
        joinedRoom.leave()

        let meeting = Meeting(code: joinedRoom.alias ?? "N/A", leaveDate: .now, backendUrl: joinedRoom.backend)
        coordinator?.meetingFinished(meeting)
    }
}

private extension ActiveMeetingViewController {
    func configure() {
        activeMeetingView.configure(displayName: displayName)
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            self.leave()
        }
        configureControls()
        configurePageController()
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak self] enabled in
            self?.setAudio(enabled: enabled)
        }

        activeMeetingView.cameraHandler = { [weak self] enabled in
            self?.setVideo(enabled: enabled)
        }
    }

    func configureMedia() {
        guard let media = media else { return }
        media.providePreview { layer in
            self.activeMeetingView.setCameraLayer(layer)
        }

        joinedRoom.setAudio(enabled: media.isAudioEnabled)
        joinedRoom.setVideo(enabled: media.isVideoEnabled)

        activeMeetingView.setMicrophone(enabled: media.isAudioEnabled)
        activeMeetingView.setCamera(enabled: media.isVideoEnabled)
    }

    func configurePageController() {
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self

        addChild(pageController)
        activeMeetingView.setPageView(pageController.view)

        configureChildControllers()

        pageController.setViewControllers([controllers[0]], direction: .forward, animated: false)
    }

    func configureChildControllers() {
        controllers.append(makeMembersViewController())
        controllers.append(makeChatViewController())
        controllers.append(makeInformationViewController(code: joinedRoom.alias ?? "N/A"))
    }

    func makeMembersViewController() -> UIViewController {
        let vc = ActiveMeetingMemberListViewController()
        membersListViewController = vc
        return vc
    }

    func makeChatViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .green
        return vc
    }

    func makeInformationViewController(code: String) -> UIViewController {
        ActiveMeetingInformationViewController(code: code)
    }

    func setVideo(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set video enabled - %{PUBLIC}d", enabled)
        joinedRoom.setVideo(enabled: enabled)
        media?.setVideo(enabled: enabled)
    }

    func setAudio(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set audio enabled - %{PUBLIC}d", enabled)
        joinedRoom.setAudio(enabled: enabled)
        media?.setAudio(enabled: enabled)
    }
}

extension ActiveMeetingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = controllers.firstIndex(of: viewController) {
            if index > 0 {
                return controllers[index - 1]
            }
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = controllers.firstIndex(of: viewController) {
            if index < controllers.count - 1 {
                return controllers[index + 1]
            }
        }

        return nil
    }
}
