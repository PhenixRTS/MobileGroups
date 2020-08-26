//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ControlButton: UIButton {
    enum ControlState {
        case on
        case off

        mutating func toggle() {
            switch self {
            case .on:
                self = .off
            case .off:
                self = .on
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted == true ? currentHighlightedBackgroundColor : currentBackgroundColor
        }
    }

    /// Image presented when **controlState** parameter is on
    private(set) var onStateImage: UIImage?

    private(set) var onStateBorderColor: UIColor = .clear
    private(set) var onStateBackgroundColor: UIColor = .clear

    private(set) var onStateHighlightedBorderColor: UIColor = .clear
    private(set) var onStateHighlightedBackgroundColor: UIColor = .clear

    /// Image presented when **controlState** parameter is off
    private(set) var offStateImage: UIImage?

    private(set) var offStateBorderColor: UIColor = .clear
    private(set) var offStateBackgroundColor: UIColor = .clear

    private(set) var offStateHighlightedBorderColor: UIColor = .clear
    private(set) var offStateHighlightedBackgroundColor: UIColor = .clear

    override var currentImage: UIImage? {
        switch controlState {
        case .on:
            return onStateImage
        case .off:
            return offStateImage
        }
    }

    var currentBorderColor: CGColor {
        switch controlState {
        case .on:
            return onStateBorderColor.cgColor
        case .off:
            return offStateBorderColor.cgColor
        }
    }

    var currentHighlightedBorderColor: CGColor {
        switch controlState {
        case .on:
            return onStateHighlightedBorderColor.cgColor
        case .off:
            return offStateHighlightedBorderColor.cgColor
        }
    }

    var currentBackgroundColor: UIColor {
        switch controlState {
        case .on:
            return onStateBackgroundColor
        case .off:
            return offStateBackgroundColor
        }
    }

    var currentHighlightedBackgroundColor: UIColor {
        switch controlState {
        case .on:
            return onStateHighlightedBackgroundColor
        case .off:
            return offStateHighlightedBackgroundColor
        }
    }

    /// Represents current control button state
    var controlState: ControlState = .on {
        didSet {
            refreshStateRepresentation()
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

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshStateRepresentation()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                layer.borderColor = currentBorderColor
            }
        }
    }

    func setImage(_ image: UIImage?, for state: ControlState) {
        switch state {
        case .on:
            onStateImage = image
        case .off:
            offStateImage = image
        }
    }

    func setBorderColor(_ color: UIColor, for state: ControlState) {
        switch state {
        case .on:
            onStateBorderColor = color
        case .off:
            offStateBorderColor = color
        }
    }

    func setBackgroundColor(_ color: UIColor, for state: ControlState) {
        switch state {
        case .on:
            onStateBackgroundColor = color
        case .off:
            offStateBackgroundColor = color
        }
    }

    func setHighlightedBorderColor(_ color: UIColor, for state: ControlState) {
        switch state {
        case .on:
            onStateHighlightedBorderColor = color
        case .off:
            offStateHighlightedBorderColor = color
        }
    }

    func setHighlightedBackgroundColor(_ color: UIColor, for state: ControlState) {
        switch state {
        case .on:
            onStateHighlightedBackgroundColor = color
        case .off:
            offStateHighlightedBackgroundColor = color
        }
    }

    func refreshStateRepresentation() {
        setImage(currentImage, for: .normal)
        backgroundColor = currentBackgroundColor
        layer.borderColor = currentBorderColor
    }
}

private extension ControlButton {
    func setup() {
        setTitleShadowColor(.black, for: .normal)

        layer.borderColor = currentBorderColor
        layer.borderWidth = 1
        layer.cornerRadius = bounds.width / 2

        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 1
        layer.masksToBounds = false
    }
}
