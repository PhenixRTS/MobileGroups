//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

extension UIImageView {
    static func makeMuteImageView() -> UIImageView {
        let image = UIImage(named: "mic_off")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowColor = UIColor.gray.cgColor
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowRadius = 0.5
        imageView.layer.masksToBounds = false

        return imageView
    }
}
