//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private(set) var coordinator: MainCoordinator?
    private var deeplink: DeeplinkModel?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        // Setup main window
        let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        self.window = window

        // Setup deeplink
        let deeplink = makeDeeplinkIfNeeded(connectionOptions)

        // Setup launcher to initiate the application components
        let launcher = Launcher(window: window, deeplink: deeplink)
        launcher.start { coordinator in
            self.coordinator = coordinator
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let deeplink = makeDeeplinkIfNeeded(userActivity) else {
            return
        }

        guard let coordinator = coordinator else {
            return
        }

        if let backend = deeplink.backend, backend != coordinator.phenixBackend {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.prepareToExit(window)
        }

        if let uri = deeplink.uri, uri != coordinator.phenixPcast {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.prepareToExit(window)
        }

        guard let code = deeplink.alias else {
            return
        }

        coordinator.join(meetingCode: code)
    }

    private func makeDeeplinkIfNeeded(_ connectionOptions: UIScene.ConnectionOptions) -> DeeplinkModel? {
        if let userActivity = connectionOptions.userActivities.first {
            return makeDeeplinkIfNeeded(userActivity)
        }

        return nil
    }

    private func makeDeeplinkIfNeeded(_ userActivity: NSUserActivity) -> DeeplinkModel? {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                let service = DeeplinkService<DeeplinkModel>(url: url)
                let deeplink = service?.decode()
                return deeplink
            }
        }

        return nil
    }
}
