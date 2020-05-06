//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

final class MicrophoneControlButton: ControlButton {
    override func controlImage(for state: ControlButton.ControlState) -> UIImage {
        switch state {
        case .on:
            // swiftlint:disable force_unwrapping
            return UIImage(named: "mic")!
        case .off:
            // swiftlint:disable force_unwrapping
            return UIImage(named: "mic_off")!
        }
    }

    override func controlBackground(for state: ControlButton.ControlState) -> UIColor {
        switch state {
        case .on:
            return .clear
        case .off:
            return .systemRed
        }
    }
}
