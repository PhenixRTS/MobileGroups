//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import AVFoundation
import Combine

class VideoLayer: AVSampleBufferDisplayLayer {
    private var needsToFlushCancellable: AnyCancellable?
    private var needsToUpdateFrameCancellable: AnyCancellable?

    override init() {
        super.init()

        if #available(iOS 14.0, *) {
            observeRequestsForFlush()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        if #available(iOS 14.0, *) {
            observeRequestsForFlush()
        }
    }

    /// Sets current layer s a sublayer to the provided destination layer.
    /// - Parameter destinationLayer: Destination layer on which to set the current layer.
    ///   If the destination layer is not provided, then just remove the current layer from its super layer, if it belongs to one.
    func set(on destinationLayer: CALayer?) {
        needsToUpdateFrameCancellable = destinationLayer?.publisher(for: \.bounds, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rect in
                CATransaction.withoutAnimations { self?.frame = rect }
            }

        DispatchQueue.main.async {
            self.removeFromSuperlayer()

            if let layer = destinationLayer {
                layer.addSublayer(self)
            }
        }
    }

    @available(iOS 14.0, *)
    private func observeRequestsForFlush() {
        needsToFlushCancellable = NotificationCenter.default
            .publisher(for: .AVSampleBufferDisplayLayerRequiresFlushToResumeDecodingDidChange)
            .sink { [weak self] notification in
                guard let self = self else {
                    return
                }

                if self.requiresFlushToResumeDecoding == true {
                    self.flush()
                }
            }
    }
}
