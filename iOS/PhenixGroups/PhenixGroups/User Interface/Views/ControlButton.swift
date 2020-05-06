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
            guard controlState == .on else {
                return
            }

            backgroundColor = isHighlighted == true ? UIColor.white.withAlphaComponent(0.2) : .clear
        }
    }

    var borderColor: CGColor? {
        guard controlState == .on else {
            return UIColor.clear.cgColor
        }

        if #available(iOS 13.0, *) {
            return UIColor(named: "Button Border Color")?.cgColor
        } else {
            return UIColor.white.cgColor
        }
    }

    var controlState: ControlState = .on {
        didSet {
            if oldValue != controlState {
                setImage(controlImage(for: controlState), for: .normal)
                backgroundColor = controlBackground(for: controlState)
                layer.borderColor = borderColor
            }
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
        setImage(controlImage(for: controlState), for: .normal)
        backgroundColor = controlBackground(for: controlState)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                layer.borderColor = UIColor(named: "Button Border Color")?.cgColor
            }
        }
    }

    func controlImage(for state: ControlState) -> UIImage {
        fatalError("Variable needs to be overridden by the subclass providing necessary values")
    }

    func controlBackground(for state: ControlState) -> UIColor {
        fatalError("Variable needs to be overridden by the subclass providing necessary values")
    }
}

private extension ControlButton {
    func setup() {
        layer.borderColor = borderColor
        layer.borderWidth = 1
        setTitleShadowColor(.black, for: .normal)
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }
}
