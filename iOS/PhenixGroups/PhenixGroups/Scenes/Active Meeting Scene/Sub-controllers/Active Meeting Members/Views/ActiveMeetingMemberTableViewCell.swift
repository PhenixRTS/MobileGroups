//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberTableViewCell: UITableViewCell, CellIdentified {
    private var cameraView: CameraView!
    private var displayNameLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        cameraView.removeCameraLayer()
    }

    func configure(displayName: String, cameraEnabled: Bool) {
        displayNameLabel.text = displayName
        showCamera(cameraEnabled)
    }

    func setCamera(_ layer: CALayer?) {
        if let layer = layer {
            cameraView.setCameraLayer(layer)
        } else {
            cameraView.removeCameraLayer()
        }
    }
}

private extension ActiveMeetingMemberTableViewCell {
    func setup() {
        cameraView = CameraView()
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.placeholderText = nil

        displayNameLabel = makeDisplayNameLabel()

        contentView.addSubview(cameraView)
        contentView.addSubview(displayNameLabel)

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: 120),
            cameraView.heightAnchor.constraint(equalToConstant: 80),

            displayNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            displayNameLabel.leadingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: 10)
        ])
    }

    func showCamera(_ show: Bool) {
        cameraView.showCamera = show
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

extension ActiveMeetingMemberTableViewCell: RoomMemberDelegate {
    func roomMemberAudioStateDidChange(_ member: RoomMember, enabled: Bool) {
        // Audio updated
    }

    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showCamera(enabled)
        }
    }
}
