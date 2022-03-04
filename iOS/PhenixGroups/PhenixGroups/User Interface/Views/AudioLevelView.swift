//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class AudioLevelView: UIView {
    enum Level {
        case low
        case medium
        case high
    }

    private var bar1: UIView!
    private var bar2: UIView!
    private var bar3: UIView!

    private var bar1HeightConstraint: NSLayoutConstraint!
    private var bar2HeightConstraint: NSLayoutConstraint!
    private var bar3HeightConstraint: NSLayoutConstraint!

    var level: Level = .low {
        didSet { levelDidChange(level) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}

private extension AudioLevelView {
    func setup() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .bottom
        stackView.axis = .horizontal
        stackView.spacing = 2

        let bar1 = UIView()
        self.bar1 = bar1
        bar1.translatesAutoresizingMaskIntoConstraints = false
        bar1.backgroundColor = .green

        let bar2 = UIView()
        self.bar2 = bar2
        bar2.translatesAutoresizingMaskIntoConstraints = false
        bar2.backgroundColor = .green

        let bar3 = UIView()
        self.bar3 = bar3
        bar3.translatesAutoresizingMaskIntoConstraints = false
        bar3.backgroundColor = .green

        stackView.addArrangedSubview(bar1)
        stackView.addArrangedSubview(bar2)
        stackView.addArrangedSubview(bar3)

        addSubview(stackView)

        bar1HeightConstraint = bar1.heightAnchor.constraint(equalToConstant: 4)
        bar2HeightConstraint = bar2.heightAnchor.constraint(equalToConstant: 4)
        bar3HeightConstraint = bar3.heightAnchor.constraint(equalToConstant: 4)

        NSLayoutConstraint.activate([
            bar1.widthAnchor.constraint(equalToConstant: 4),
            bar2.widthAnchor.constraint(equalToConstant: 4),
            bar3.widthAnchor.constraint(equalToConstant: 4),

            bar1HeightConstraint,
            bar2HeightConstraint,
            bar3HeightConstraint,

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func levelDidChange(_ level: Level) {
        switch level {
        case .low:
            bar1HeightConstraint.constant = 4
            bar2HeightConstraint.constant = 4
            bar3HeightConstraint.constant = 4

        case .medium:
            bar1HeightConstraint.constant = 4
            bar2HeightConstraint.constant = 8
            bar3HeightConstraint.constant = 4

        case .high:
            bar1HeightConstraint.constant = 8
            bar2HeightConstraint.constant = 8
            bar3HeightConstraint.constant = 8
        }
    }
}
