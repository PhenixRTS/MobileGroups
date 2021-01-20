//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class TabBarButton: UIButton {
    private var observation: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func observe(titleChangesOf controller: UIViewController) {
        observation = controller.observe(\.title, options: [.new]) { [weak self] _, change in
            guard let title = change.newValue else { return }
            DispatchQueue.main.async {
                self?.setTitle(title, for: .normal)
            }
        }
    }
}

private extension TabBarButton {
    func setup() {
        titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        if #available(iOS 13.0, *) {
            setTitleColor(.label, for: .normal)
        } else {
            setTitleColor(.black, for: .normal)
        }
    }
}
