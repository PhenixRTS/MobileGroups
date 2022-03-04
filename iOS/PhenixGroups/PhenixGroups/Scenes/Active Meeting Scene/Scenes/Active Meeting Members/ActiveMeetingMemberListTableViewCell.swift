//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListTableViewCell: UITableViewCell, CellIdentified {
    private lazy var cameraView: CameraView = {
        // CameraView must have preferred size (before AutoLayout updates its size),
        // so that VideoLayer could work properly without any assertions of source view size being zero.
        let view = CameraView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholderText = nil
        return view
    }()

    private lazy var pinView: CameraPinView = {
        let view = CameraPinView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    private lazy var muteImage: UIImageView = {
        let view = UIImageView.makeMuteImageView()
        view.clipsToBounds = false
        view.tintColor = .white
        return view
    }()

    private lazy var muteImageBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemRed
        return view
    }()

    private lazy var audioLevelView: AudioLevelView = {
        let view = AudioLevelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var awayImageView: UIImageView = {
        let view = UIImageView.makeAwayImageView()
        return view
    }()

    private var viewModel: ViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        muteImageBackground.layer.cornerRadius = muteImageBackground.frame.width / 2
    }

    func pin() {
        pinView.isHidden = false
    }

    func unpin() {
        pinView.isHidden = true
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        viewModel.delegate = self
        viewModel.subscribeForEvents()

        renderPreviewIfNeeded()
        displayNameLabel.text = viewModel.displayName
    }

    func renderPreviewIfNeeded() {
        viewModel?.renderPreviewIfNeeded(on: cameraView.cameraLayer)
    }

    // MARK: - Private methods

    private func setup() {
        selectionStyle = .none

        contentView.addSubview(cameraView)
        contentView.addSubview(pinView)
        contentView.addSubview(displayNameLabel)
        contentView.addSubview(muteImage)
        contentView.insertSubview(muteImageBackground, belowSubview: muteImage)
        contentView.addSubview(audioLevelView)
        contentView.addSubview(awayImageView)

        setupConstraints()
    }

    private func setupConstraints() {
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

            muteImage.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            muteImage.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: -8),
            muteImage.widthAnchor.constraint(equalToConstant: 14),
            muteImage.heightAnchor.constraint(equalToConstant: 14),

            muteImageBackground.topAnchor.constraint(equalTo: muteImage.topAnchor, constant: -4),
            muteImageBackground.leadingAnchor.constraint(equalTo: muteImage.leadingAnchor, constant: -4),
            muteImageBackground.trailingAnchor.constraint(equalTo: muteImage.trailingAnchor, constant: 4),
            muteImageBackground.bottomAnchor.constraint(equalTo: muteImage.bottomAnchor, constant: 4),

            audioLevelView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -6),
            audioLevelView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: -6),

            awayImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            awayImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            awayImageView.widthAnchor.constraint(equalToConstant: 18),
            awayImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func setMicrophoneMuteIcon(visible: Bool) {
        let isHidden = visible == false
        muteImage.isHidden = isHidden
        muteImageBackground.isHidden = isHidden
    }

    private func showAudioLevelIndicator(_ show: Bool) {
        audioLevelView.isHidden = show == false
    }

    private func showCamera(_ show: Bool) {
        cameraView.showCamera = show
    }

    private func setAway(_ enabled: Bool) {
        awayImageView.isHidden = !enabled
    }
}

// MARK: - ActiveMeetingMemberListTableViewCellModelDelegate
extension ActiveMeetingMemberListTableViewCell: ActiveMeetingMemberListTableViewCellModelDelegate {
    func viewModel(_ viewModel: ViewModel, didChangeAudioState enabled: Bool) {
        setMicrophoneMuteIcon(visible: enabled == false)
        showAudioLevelIndicator(enabled)
    }

    func viewModel(_ viewModel: ViewModel, didChangeVideoState enabled: Bool) {
        showCamera(viewModel.showsCamera)
        renderPreviewIfNeeded()
    }

    func viewModel(_ viewModel: ViewModel, didChangeConnectionState state: PhenixCore.Member.ConnectionState) {
        setAway(state == .away)
    }

    func viewModel(_ viewModel: ViewModel, didChangeSelectionState isSelected: Bool) {
        if isSelected {
            pin()
        } else {
            unpin()
        }

        showCamera(viewModel.showsCamera)
        renderPreviewIfNeeded()
    }

    func viewModel(_ viewModel: ViewModel, didChangeVolume level: AudioLevelView.Level) {
        audioLevelView.level = level
    }
}
