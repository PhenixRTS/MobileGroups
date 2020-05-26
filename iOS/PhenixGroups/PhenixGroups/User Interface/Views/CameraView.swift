//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class CameraView: UIView {
    private var cameraLayer: CALayer?

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
}

private extension CameraView {
    func setup() {
        layer.masksToBounds = true
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
