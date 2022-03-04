//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraPinView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CameraPinView {
    func setup() {
        backgroundColor = .systemGray3

        let imageView = makeImageView()

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - UI Element Factory methods
private extension CameraPinView {
    func makeImageView() -> UIImageView {
        let image = UIImage(systemName: "pin.fill")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .gray

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return imageView
    }
}
