//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

extension UIImageView {
    static func makeMuteImageView() -> UIImageView {
        let image = UIImage(systemName: "mic.slash.fill")
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

    static func makeAwayImageView() -> UIImageView {
        let image = UIImage(systemName: "moon.zzz.fill")
        let imageView = UIImageView(image: image)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowColor = UIColor.gray.cgColor
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowRadius = 0.5
        imageView.layer.masksToBounds = false

        return imageView
    }
}
