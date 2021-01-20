//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingInformationViewController: UIViewController, PageContainerMember {
    lazy var pageIcon = UIImage(named: "meeting_information_icon")

    private var titleLabel: UILabel!
    private var codeLabel: UILabel!
    private var shareButton: UIButton!

    private let code: String
    // swiftlint:disable force_unwrapping
    private lazy var meetingUrl = URL(string: "https://phenixrts.com/group/#\(code)")!

    init(code: String) {
        self.code = code

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }

    @objc
    func shareButtonTapped() {
        let text = "Meeting URL: \(meetingUrl.absoluteString)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = shareButton
        present(vc, animated: true)
    }
}

private extension ActiveMeetingInformationViewController {
    func configure() {
        titleLabel = UILabel.makeTitleLabel()
        codeLabel = UILabel.makeCodeLabel(code)
        shareButton = UIButton.makeShareButton()
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)

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

// MARK: - UI Element Factory methods
fileprivate extension UILabel {
    static func makeTitleLabel() -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Meeting code:"
        label.font = .preferredFont(forTextStyle: .body)
        label.sizeToFit()
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .gray
        }

        return label
    }

    static func makeCodeLabel(_ code: String) -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = code
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .systemOrange
        label.sizeToFit()

        return label
    }
}

fileprivate extension UIButton {
    static func makeShareButton() -> UIButton {
        let image = UIImage(named: "square.and.arrow.up")
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.setTitle("Share", for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 0, right: 0)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.tintColor = .systemOrange

        return button
    }
}
