//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class CameraView: UIView {
    private var cameraPlaceholderView: CameraPlaceholderView!
    private var cameraLayerView: UIView!

    var cameraLayer: CALayer {
        cameraLayerView.layer
    }

    var showCamera = true {
        didSet { cameraLayerView.isHidden = !showCamera }
    }

    var placeholderText: String? {
        didSet { cameraPlaceholderView.text = placeholderText }
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
        cameraLayerView.layer.sublayers?.forEach { layer in
            layer.resize(as: cameraLayerView.layer)
        }
    }

    func removeCameraLayer() {
        cameraLayer.removeFromSuperlayer()
    }
}

private extension CameraView {
    func setup() {
        layer.masksToBounds = true

        cameraPlaceholderView = CameraPlaceholderView()
        cameraPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        cameraPlaceholderView.text = nil

        cameraLayerView = UIView()
        cameraLayerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cameraPlaceholderView)
        addSubview(cameraLayerView)

        NSLayoutConstraint.activate([
            cameraLayerView.topAnchor.constraint(equalTo: topAnchor),
            cameraLayerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraLayerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraLayerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cameraPlaceholderView.topAnchor.constraint(equalTo: topAnchor),
            cameraPlaceholderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraPlaceholderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraPlaceholderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

fileprivate extension CALayer {
    func resize(as otherLayer: CALayer) {
        CATransaction.withoutAnimations {
            self.frame = otherLayer.bounds
        }
    }
}
