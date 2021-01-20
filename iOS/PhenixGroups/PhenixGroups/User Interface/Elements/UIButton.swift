//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

extension UIButton {
    static func makePrimaryButton(withTitle title: String) -> UIButton {
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemOrange
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.allowsDefaultTighteningForTruncation = true
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setTitle(title, for: .normal)

        return button
    }

    static func makeMenuButton() -> UIButton {
        let image = UIImage(named: "menu")
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        if #available(iOS 13.0, *) {
            button.tintColor = .systemBackground
        } else {
            button.tintColor = .black
        }
        button.contentMode = .scaleAspectFit
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 0.5
        button.layer.masksToBounds = false

        return button
    }
}
