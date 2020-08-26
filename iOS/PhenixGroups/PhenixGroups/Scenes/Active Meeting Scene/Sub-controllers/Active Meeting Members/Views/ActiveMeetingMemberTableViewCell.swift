//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberTableViewCell: UITableViewCell, CellIdentified {
    private var cameraView: CameraView!
    private var pinView: CameraPinView!
    private var displayNameLabel: UILabel!
    private var muteImage: UIImageView!
    private var muteImageBackground: UIView!

    weak var member: RoomMember! {
        didSet {
            oldValue?.removeAudioObserver(self)
            oldValue?.removeVideoObserver(self)
        }
    }

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

    override func layoutSubviews() {
        super.layoutSubviews()

        muteImageBackground.layer.cornerRadius = muteImageBackground.frame.width / 2
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
        showMuteIcon(member.isAudioAvailable == false)
        member.addAudioObserver(self)
    }

    func configureVideo() {
        setCamera(layer: member.previewLayer)
        showCamera(member.isVideoAvailable)
        member.addVideoObserver(self)
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

        muteImage = UIImageView.makeMuteImageView()
        muteImage.clipsToBounds = false
        muteImage.tintColor = .white
        muteImage.contentMode = .scaleAspectFill

        muteImageBackground = UIView()
        muteImageBackground.translatesAutoresizingMaskIntoConstraints = false
        muteImageBackground.backgroundColor = .systemRed

        contentView.addSubview(cameraView)
        contentView.addSubview(pinView)
        contentView.addSubview(displayNameLabel)
        contentView.addSubview(muteImage)
        contentView.insertSubview(muteImageBackground, belowSubview: muteImage)

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

            displayNameLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            displayNameLabel.leadingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: 10),
            displayNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            displayNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            displayNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            muteImage.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -6),
            muteImage.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: -6),
            muteImage.widthAnchor.constraint(equalToConstant: 18),
            muteImage.heightAnchor.constraint(equalToConstant: 18),

            muteImageBackground.topAnchor.constraint(equalTo: muteImage.topAnchor, constant: -2),
            muteImageBackground.leadingAnchor.constraint(equalTo: muteImage.leadingAnchor, constant: -2),
            muteImageBackground.trailingAnchor.constraint(equalTo: muteImage.trailingAnchor, constant: 2),
            muteImageBackground.bottomAnchor.constraint(equalTo: muteImage.bottomAnchor, constant: 2)
        ])
    }

    func showMuteIcon(_ show: Bool) {
        let isHidden = show == false
        muteImage.isHidden = isHidden
        muteImageBackground.isHidden = isHidden
    }

    func showCamera(_ show: Bool) {
        cameraView.showCamera = show
    }
}

// MARK: - RoomMemberAudioObserver
extension ActiveMeetingMemberTableViewCell: RoomMemberAudioObserver {
    func roomMemberAudioStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showMuteIcon(enabled == false)
        }
    }
}

// MARK: - RoomMemberVideoObserver
extension ActiveMeetingMemberTableViewCell: RoomMemberVideoObserver {
    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showCamera(enabled)
        }
    }
}

// MARK: - UI Element Factory methods
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
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true

        return label
    }

    func makePinView() -> CameraPinView {
        let view = CameraPinView()

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
