//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class PlaceholderTextView: UITextView {
    private lazy var placeholderLabel: UILabel! = {
        let label = makePlaceholderLabel()

        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        return label
    }()

    var placeholder: String? {
        get { placeholderLabel.text }
        set { placeholderLabel.text = newValue }
    }

    var placeholderColor: UIColor {
        get { placeholderLabel.textColor }
        set { placeholderLabel.textColor = newValue }
    }

    override var text: String! {
        didSet {
            setPlaceholder(visible: text.isEmpty)
        }
    }

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    var isPlaceholderVisible: Bool {
        placeholderLabel.isHidden == false
    }

    override func draw(_ rect: CGRect) {
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
    }

    func setPlaceholder(visible: Bool) {
        placeholderLabel.isHidden = visible == false
    }
}

// MARK: - UI Element Factory methods
private extension PlaceholderTextView {
    func makePlaceholderLabel() -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = font
        if #available(iOS 13.0, *) {
            label.textColor = .placeholderText
        } else {
            label.textColor = .systemGray
        }

        return label
    }
}
