//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraView: UIView {
    private var cameraLayer: CALayer?
    private var cameraPlaceholderView: CameraPlaceholderView!

    var showCamera: Bool = true {
        didSet {
            cameraLayer?.isHidden = !showCamera
        }
    }

    var placeholderText: String? {
        didSet {
            cameraPlaceholderView.text = placeholderText
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

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraLayer?.resize(as: layer)
    }

    func setCameraLayer(_ cameraLayer: CALayer) {
        self.cameraLayer?.removeFromSuperlayer()

        self.cameraLayer = cameraLayer
        layer.add(cameraLayer)
    }

    func removeCameraLayer() {
        cameraLayer?.removeFromSuperlayer()
        cameraLayer = nil
    }
}

private extension CameraView {
    func setup() {
        layer.masksToBounds = true

        cameraPlaceholderView = CameraPlaceholderView()
        cameraPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        cameraPlaceholderView.text = nil

        addSubview(cameraPlaceholderView)

        NSLayoutConstraint.activate([
            cameraPlaceholderView.topAnchor.constraint(equalTo: topAnchor),
            cameraPlaceholderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraPlaceholderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraPlaceholderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

fileprivate extension CALayer {
    func resize(as otherLayer: CALayer) {
        frame = otherLayer.bounds
    }

    func add(_ layer: CALayer) {
        layer.resize(as: self)
        addSublayer(layer)
    }
}
