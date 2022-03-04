//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
        let image = UIImage(systemName: "line.3.horizontal")
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.tintColor = .systemBackground
        button.contentMode = .scaleAspectFit
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 0.5
        button.layer.masksToBounds = false

        return button
    }
}

extension ControlButton {
    func configureAsMicrophoneButton() {
        tintColor = .systemBackground

        setImage(.init(systemName: "mic.fill"), for: .on)
        setImage(.init(systemName: "mic.slash.fill"), for: .off)

        setBorderColor(.systemBackground, for: .on)
        setBorderColor(.clear, for: .off)
        setHighlightedBorderColor(.systemBackground, for: .on)
        setHighlightedBorderColor(.clear, for: .off)

        setBackgroundColor(.clear, for: .on)
        setBackgroundColor(.systemRed, for: .off)
        setHighlightedBackgroundColor(UIColor.white.withAlphaComponent(0.2), for: .on)
        setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        refreshStateRepresentation()
    }

    func configureAsCameraButton() {
        tintColor = .systemBackground

        setImage(.init(systemName: "video.fill"), for: .on)
        setImage(.init(systemName: "video.slash.fill"), for: .off)

        setBorderColor(.systemBackground, for: .on)
        setBorderColor(.clear, for: .off)
        setHighlightedBorderColor(.systemBackground, for: .on)
        setHighlightedBorderColor(.clear, for: .off)

        setBackgroundColor(.clear, for: .on)
        setBackgroundColor(.systemRed, for: .off)
        setHighlightedBackgroundColor(UIColor.white.withAlphaComponent(0.2), for: .on)
        setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        refreshStateRepresentation()
    }

    func configureAsLeaveMeetingButton() {
        tintColor = .systemBackground

        setImage(.init(systemName: "phone.down.fill"), for: .on)
        setImage(.init(systemName: "phone.down.fill"), for: .off)

        setBorderColor(.clear, for: .on)
        setBorderColor(.clear, for: .off)
        setHighlightedBorderColor(.clear, for: .on)
        setHighlightedBorderColor(.clear, for: .off)

        setBackgroundColor(.systemRed, for: .on)
        setBackgroundColor(.systemRed, for: .off)
        setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .on)
        setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        refreshStateRepresentation()
    }
}
