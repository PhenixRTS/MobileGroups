//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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

    func selectTab(_ index: Int) {
        view.endEditing(true)
        move(toPage: index)
    }

    @objc
    func tabButtonTapped(_ sender: UIButton) {
        selectTab(sender.tag)
    }

    func setControllers(_ controllers: [UIViewController]) {
        for controller in controllers {
            controller.view.removeFromSuperview()
        }

        self.controllers = controllers

        configureChildControllers(controllers)

        var tag = 0
        controllers.forEach { controller in
            guard let properties = controller as? PageContainerMember else { return }

            let button = makeTabButton(icon: properties.pageIcon, title: controller.title ?? "", tag: tag)
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

    func move(toPage index: Int) {
        let point = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(point, animated: true)
    }

    func configureChildControllers(_ controllers: [UIViewController]) {
        for (index, controller) in controllers.enumerated() {
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            addChild(controller)
            scrollView.addSubview(controller.view)
            controller.didMove(toParent: self)

            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                controller.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])

            if controllers.count == 1 {
                // If there is only one page
                controller.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
                controller.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            } else if index == 0 {
                // First page
                controller.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            } else if index + 1 == controllers.count {
                // Last page
                controller.view.leadingAnchor.constraint(equalTo: controllers[index - 1].view.trailingAnchor).isActive = true
                controller.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            } else {
                // Middle pages
                controller.view.leadingAnchor.constraint(equalTo: controllers[index - 1].view.trailingAnchor).isActive = true
            }
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
    var pageCount: Int {
        Int(contentSize.width / bounds.width)
    }

    /// Current page begins with index 0
    var currentPage: Int {
        let current = Int((contentOffset.x / bounds.width).rounded(.toNearestOrEven))
        return max(min(current, pageCount - 1), 0)
    }
}
