//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraPlaceholderView: UIView {
    private var imageView: UIImageView!
    private var displayNameLabel: UILabel!

    var text: String = "" {
        didSet {
            displayNameLabel.text = text
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func makeImageView() -> UIImageView {
        guard let image = UIImage(named: "camera_placeholder") else {
            fatalError("Could not locate necessary image")
        }

        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])

        return imageView
    }

    func makeCaption() -> UILabel {
        let label = UILabel()
        displayNameLabel = label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.sizeToFit()

        return label
    }
}
