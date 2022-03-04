//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import UIKit

class TabBarButton: UIButton {
    private var cancellable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func observe(titleChangesOf controller: UIViewController) {
        cancellable = controller.publisher(for: \.title)
            .sink { [weak self] title in
                self?.setTitle(title, for: .normal)
            }
    }
}

private extension TabBarButton {
    func setup() {
        titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        setTitleColor(.label, for: .normal)
    }
}
