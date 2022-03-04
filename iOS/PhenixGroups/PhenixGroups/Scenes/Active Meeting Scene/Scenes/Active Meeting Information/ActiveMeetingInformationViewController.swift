//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingInformationViewController: UIViewController, PageContainerMember {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Meeting code:"
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.sizeToFit()
        return label
    }()

    private lazy var codeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.meetingCode
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .systemOrange
        label.sizeToFit()
        return label
    }()

    private lazy var shareButton: UIButton = {
        let image = UIImage(systemName: "square.and.arrow.up")
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.setTitle("Share", for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 0, right: 0)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.tintColor = .systemOrange
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()

    var viewModel: ViewModel!

    lazy var pageIcon = UIImage(systemName: "info.circle")

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    @objc
    func shareButtonTapped() {
        let text = viewModel.sharableText
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = shareButton
        present(activityController, animated: true)
    }
}

// MARK: - Private methods
private extension ActiveMeetingInformationViewController {
    func setup() {
        view.addSubview(titleLabel)
        view.addSubview(codeLabel)
        view.addSubview(shareButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            codeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            codeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            codeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            codeLabel.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor),

            shareButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            shareButton.widthAnchor.constraint(equalToConstant: 80),
            shareButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
