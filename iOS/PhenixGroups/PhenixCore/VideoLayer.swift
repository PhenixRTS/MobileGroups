//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

public class VideoLayer: CALayer {
    public static let name = "Video Layer"

    override public init() {
        super.init()
        configure()
    }

    override public init(layer: Any) {
        super.init(layer: layer)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension VideoLayer {
    func configure() {
        name = Self.name
        isOpaque = false
        removeAllAnimations()
    }
}
