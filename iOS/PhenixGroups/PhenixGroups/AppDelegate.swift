//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixDeeplink
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private(set) var coordinator: MainCoordinator?

    /// Provide an alert with information and then terminate the application
    ///
    /// - Parameters:
    ///   - title: Title for the alert
    ///   - message: Message for the alert
    ///   - file: The file name to print with `message`. The default is the file
    ///   where `terminate(afterDisplayingAlertWithTitle:message:file:line:)` is called.
    ///   - line: The line number to print along with `message`. The default is the line number where
    ///   `terminate(afterDisplayingAlertWithTitle:message:file:line:)` is called.
    static func terminate(afterDisplayingAlertWithTitle title: String, message: String, file: StaticString = #file, line: UInt = #line) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
              let window = delegate.window else {
            fatalError(message)
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close app", style: .default) { _ in
            fatalError(message, file: file, line: line)
        })

        window.rootViewController?.presentedViewController?.dismiss(animated: false)
        window.rootViewController?.present(alert, animated: true)
    }

    static func present(alertWithTitle title: String, message: String? = nil) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
              let window = delegate.window else {
            fatalError("Fatal error. Could not load window instance.")
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        if let vc = window.rootViewController?.presentedViewController {
            vc.present(alert, animated: true)
        } else {
            window.rootViewController?.present(alert, animated: true)
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup main window
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        // Setup deeplink
        let deeplink = PhenixDeeplinkService<PhenixDeeplinkModel>.makeDeeplink(launchOptions)

        // Setup launcher to initiate the application components
        let launcher = Launcher(window: window, deeplink: deeplink)
        launcher.start { coordinator in
            self.coordinator = coordinator
        }

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let deeplink = PhenixDeeplinkService<PhenixDeeplinkModel>.makeDeeplink(userActivity) else {
            return false
        }

        // If the coodinator does not exist, it means that he app hasn't started yet or is just now starting.
        // Note: If app receives a URL at the app launch state, after the `application(_:didFinishLaunchingWithOptions:) -> Bool` finishes this method will be executed next, so both methods will try to use deeplink, but on app launch this method does not need to be executed.
        guard let coordinator = coordinator else {
            return false
        }

        let terminate: () -> Void = {
            Self.terminate(
                afterDisplayingAlertWithTitle: "Configuration has changed.",
                message: "Please start the app again to apply the changes."
            )
        }

        if let backend = deeplink.backend, backend != coordinator.phenixBackend {
            terminate()
            return false
        }

        if let uri = deeplink.uri, uri != coordinator.phenixPcast {
            terminate()
            return false
        }

        if let maxVideoMembers = deeplink.maxVideoMembers, maxVideoMembers != coordinator.phenixMaxVideoSubscriptions {
            terminate()
            return false
        }

        guard let code = deeplink.alias else {
            return false
        }

        coordinator.join(meetingCode: code)

        return true
    }
}
