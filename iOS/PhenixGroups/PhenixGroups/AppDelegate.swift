//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private(set) var coordinator: MainCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 13.0, *) {
            // All magic happens in SceneDelegate.swift
            return true
        }

        // Setup main window
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        // Setup deeplink
        let deeplink = makeDeeplinkIfNeeded(launchOptions)

        // Setup launcher to initiate the application components
        let launcher = Launcher(window: window, deeplink: deeplink)
        launcher.start { coordinator in
            self.coordinator = coordinator
        }

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let deeplink = makeDeeplinkIfNeeded(userActivity) else {
            return false
        }

        // If the coodinator does not exist, it means that he app hasn't started yet or is just now starting.
        // Note: If app receives a URL at the app launch state, after the `application(_:didFinishLaunchingWithOptions:) -> Bool` finishes this method will be executed next, so both methods will try to use deeplink, but on app launch this method does not need to be executed.
        guard let coordinator = coordinator else {
            return false
        }

        if let backend = deeplink.backend, backend != coordinator.phenixBackend {
            prepareToExit(window)
        }

        if let uri = deeplink.uri, uri != coordinator.phenixPcast {
            prepareToExit(window)
        }

        guard let code = deeplink.alias else {
            return false
        }

        coordinator.join(meetingCode: code)

        return true
    }

    func prepareToExit(_ window: UIWindow?) {
        let alert = UIAlertController(
            title: "Configuration has changed.",
            message: "Please start the app again to apply the changes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Close app", style: .default) { _ in
            fatalError("Configuration has changed. App needs to be restarted.")
        })

        if let nc = window?.rootViewController as? UINavigationController {
            nc.present(alert, animated: true)
        }
    }

    private func makeDeeplinkIfNeeded(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> DeeplinkModel? {
        if let options = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
            if let userActivity = options[UIApplication.LaunchOptionsKey.userActivityKey] as? NSUserActivity {
                return makeDeeplinkIfNeeded(userActivity)
            }
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

extension UIApplication.LaunchOptionsKey {
    static let userActivityKey = "UIApplicationLaunchOptionsUserActivityKey"
}
