//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraPlaceholderView: UIView {
    private var imageView: UIImageView!
    private var textLabel: UILabel!

    var text: String? {
        didSet {
            textLabel.text = text
            textLabel.isHidden = text == nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CameraPlaceholderView {
    func setup() {
        if #available(iOS 13.0, *) {
            backgroundColor = .systemGray3
        } else {
            backgroundColor = .gray
        }

        let stack = UIStackView(arrangedSubviews: [
            makeImageView(),
            makeCaption()
        ])

        self.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 20

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - UI Element Factory methods
private extension CameraPlaceholderView {
    func makeImageView() -> UIImageView {
        let image = UIImage(named: "camera_placeholder")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])

        return imageView
    }

    func makeCaption() -> UILabel {
        let label = UILabel()
        textLabel = label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.sizeToFit()

        return label
    }
}
