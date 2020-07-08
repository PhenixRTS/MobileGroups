//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberTableViewCell: UITableViewCell, CellIdentified {
    private var cameraView: CameraView!
    private var pinView: CameraPinView!
    private var displayNameLabel: UILabel!

    weak var member: RoomMember!

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
        unpin()
    }

    func setCamera(layer: VideoLayer?) {
        if let layer = layer {
            cameraView.setCameraLayer(layer)
        } else {
            cameraView.removeCameraLayer()
        }
    }

    func pin() {
        pinView.isHidden = false
    }

    func unpin() {
        pinView.isHidden = true
    }

    func configure(member: RoomMember) {
        self.member = member
        displayNameLabel.text = member.screenName
        showCamera(false)
    }

    func configureVideo() {
        setCamera(layer: member.previewLayer)
        showCamera(member.isVideoAvailable)

        member.delegate = self
    }
}

private extension ActiveMeetingMemberTableViewCell {
    func setup() {
        // CameraView must have preferred size (before AutoLayout updates its size) so that VideoLayer could work properly without any assertions of source view size being zero.
        cameraView = CameraView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.placeholderText = nil

        pinView = makePinView()
        pinView.isHidden = true

        displayNameLabel = makeDisplayNameLabel()

        contentView.addSubview(cameraView)
        contentView.addSubview(pinView)
        contentView.addSubview(displayNameLabel)

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: 120),
            cameraView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            pinView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            pinView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            pinView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            pinView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),

            displayNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            displayNameLabel.leadingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: 10)
        ])
    }

    func showCamera(_ show: Bool) {
        cameraView.showCamera = show
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

// MARK: - Helper methods
extension ActiveMeetingMemberTableViewCell {
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

    func makePinView() -> CameraPinView {
        let view = CameraPinView()

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
