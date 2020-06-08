//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraPlaceholderView: UIView {
    enum Size {
        case small
        case big

        var width: CGFloat {
            switch self {
            case .small:
                return 40
            case .big:
                return 80
            }
        }

        var height: CGFloat {
            switch self {
            case .small:
                return 40
            case .big:
                return 80
            }
        }
    }

    private var imageView: UIImageView!
    private var displayNameLabel: UILabel!

    let size: CameraPlaceholderView.Size

    var text: String = "" {
        didSet {
            displayNameLabel.text = text
        }
    }

    var displayNameEnabled: Bool = true {
        didSet {
            displayNameLabel.isHidden = displayNameEnabled == false
        }
    }

    init(size: CameraPlaceholderView.Size, frame: CGRect = .zero) {
        self.size = size
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
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func makeImageView() -> UIImageView {
        let image = UIImage(named: "camera_placeholder")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: size.width),
            imageView.heightAnchor.constraint(equalToConstant: size.height)
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
