//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraPlaceholderView: UIView {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "person.crop.rectangle.fill"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .gray

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 50)
        ])

        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.sizeToFit()
        return label
    }()

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
        backgroundColor = .systemGray3

        let stack = UIStackView(arrangedSubviews: [imageView, textLabel])

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
