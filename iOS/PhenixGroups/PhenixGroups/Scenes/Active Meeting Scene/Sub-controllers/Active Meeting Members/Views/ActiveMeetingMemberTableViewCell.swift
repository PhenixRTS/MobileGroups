//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberTableViewCell: UITableViewCell, CellIdentified {
    private var cameraView: CameraView!
    private var cameraPlaceholderView: CameraPlaceholderView!
    private var displayNameLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(displayName: String) {
        displayNameLabel.text = displayName
        showCamera(false)
    }
}

private extension ActiveMeetingMemberTableViewCell {
    func setup() {
        cameraView = CameraView()
        cameraView.backgroundColor = .green
        cameraView.translatesAutoresizingMaskIntoConstraints = false

        cameraPlaceholderView = makeCameraPlaceholderView()

        displayNameLabel = makeDisplayNameLabel()

        contentView.addSubview(cameraView)
        contentView.addSubview(cameraPlaceholderView)
        contentView.addSubview(displayNameLabel)

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: 120),
            cameraView.heightAnchor.constraint(equalToConstant: 60),

            cameraPlaceholderView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            cameraPlaceholderView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            cameraPlaceholderView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            cameraPlaceholderView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),

            displayNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            displayNameLabel.leadingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: 10)
        ])
    }

    func makeCameraPlaceholderView() -> CameraPlaceholderView {
        let view = CameraPlaceholderView(size: .small)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.displayNameEnabled = false

        return view
    }

    func showCamera(_ show: Bool) {
        cameraView.isHidden = !show
        cameraPlaceholderView.isHidden = show
    }

    func makeDisplayNameLabel() -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .gray
        }

        return label
    }
}
