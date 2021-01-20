//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class PageViewController: UIViewController {
    private var indicator: UIView!
    private var tabStackView: UIStackView!
    private var scrollView: UIScrollView!
    private(set) var selectedTabIndex = 0
    private(set) var controllers = [UIViewController]()

    init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        indicator.frame.size.width = view.frame.width / CGFloat(controllers.count)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        // Scroll view has a different position for portrait mode and landscape mode and when device rotates,
        // scroll view automatically scrolls, so we need to disable delegate method capturing to prevent of having
        // an incorrect scroll position saved by the `scrollViewDidScroll(_:)` delegate method.
        scrollView.delegate = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Select the previously selected tab
        selectTab(selectedTabIndex, withAnimation: false)
        // Manually call the scroll view delegate method to update the tab indicator position.
        scrollViewDidScroll(scrollView)
        // Set the delegate method back, because the device rotation has finished.
        scrollView.delegate = self
    }

    func selectTab(_ index: Int, withAnimation animated: Bool = true) {
        view.endEditing(true)
        // Need to refresh the scroll view layout so that the scroll position would be calculated correctly.
        // Layout calculation is necessary, for example, if user rotate the device.
        scrollView.layoutIfNeeded()
        move(toPage: index, animated: animated)
    }

    @objc
    func tabButtonTapped(_ sender: UIButton) {
        selectTab(sender.tag)
    }

    func setControllers(_ controllers: [UIViewController]) {
        // Remove old controller views if there are some from the parent view
        controllers.forEach { $0.view.removeFromSuperview() }

        set(childControllers: controllers)

        var tag = 0
        controllers.forEach { controller in
            guard let properties = controller as? PageContainerMember else { return }

            let button = makeTabButton(icon: properties.pageIcon, title: properties.title ?? "", tag: tag)
            if controller is ActiveMeetingMemberListViewController {
                button.observe(titleChangesOf: controller)
            }
            tabStackView.addArrangedSubview(button)
            tag += 1
        }
    }
}

private extension PageViewController {
    func setup() {
        view.isOpaque = true

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        scrollView = makeScrollView()
        scrollView.delegate = self

        tabStackView = makeTabContainerView()
        indicator = makeIndicator()
        indicator.frame = CGRect(x: 0, y: 58, width: view.frame.width, height: 2)

        view.addSubview(scrollView)
        view.addSubview(tabStackView)
        view.addSubview(indicator)

        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: view.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabStackView.heightAnchor.constraint(equalToConstant: 60),

            scrollView.topAnchor.constraint(equalTo: tabStackView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func moveIndicator(to point: CGFloat) {
        indicator.frame.origin.x = point
    }

    func move(toPage index: Int, animated: Bool = true) {
        let point = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(point, animated: animated)
    }

    /// Adds view controllers to the current controller as child view controllers and positions them horizontally next to each other in the scroll view
    /// - Parameter controllers: List with the child UIViewController's
    func set(childControllers controllers: [UIViewController]) {
        if self.controllers.isEmpty == false {
            self.controllers.forEach { $0.remove() }
        }

        self.controllers = controllers

        for (index, controller) in controllers.enumerated() {
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            add(controller, into: scrollView)

            var constraints = [
                controller.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                controller.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ]

            if controllers.count == 1 {
                // If there is only one page
                constraints += [
                    controller.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    controller.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
                ]
            } else if index == 0 {
                // First page
                constraints += [
                    controller.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
                ]
            } else if index + 1 == controllers.count {
                // Last page
                constraints += [
                    controller.view.leadingAnchor.constraint(equalTo: controllers[index - 1].view.trailingAnchor),
                    controller.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
                ]
            } else {
                // Middle pages
                constraints += [
                    controller.view.leadingAnchor.constraint(equalTo: controllers[index - 1].view.trailingAnchor)
                ]
            }

            NSLayoutConstraint.activate(constraints)
        }
    }
}

private extension PageViewController {
    func makeTabContainerView() -> UIStackView {
        let stack = UIStackView()

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually

        return stack
    }

    func makeTabButton(icon: UIImage?, title: String, tag: Int) -> TabBarButton {
        let button = TabBarButton(type: .system)

        button.setImage(icon, for: .normal)
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(tabButtonTapped), for: .touchUpInside)
        button.tag = tag

        return button
    }

    func makeIndicator() -> UIView {
        let view = UIView()

        if #available(iOS 13.0, *) {
            view.backgroundColor = .label
        } else {
            view.backgroundColor = .black
        }

        return view
    }

    func makeScrollView() -> UIScrollView {
        let view = UIScrollView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.keyboardDismissMode = .onDrag

        return view
    }
}

extension PageViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.bounds.width / scrollView.contentSize.width * scrollView.contentOffset.x
        moveIndicator(to: point)
        selectedTabIndex = scrollView.currentPage
    }
}

fileprivate extension UIScrollView {
    var pageCount: Int { Int(contentSize.width / bounds.width) }

    /// Current page begins with index 0
    var currentPage: Int {
        let current = Int((contentOffset.x / bounds.width).rounded(.toNearestOrEven))
        return max(min(current, pageCount - 1), 0)
    }
}
