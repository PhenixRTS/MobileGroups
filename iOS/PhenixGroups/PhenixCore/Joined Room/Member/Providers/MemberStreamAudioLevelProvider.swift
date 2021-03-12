//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

class MemberStreamAudioLevelProvider: RoomMemberDescription {
    static let minimumDecibel: Double = -100.0
    static let maximumDecibel: Double = 0.0

    private let queue: DispatchQueue
    private let renderer: PhenixRenderer
    private let audioTracks: [PhenixMediaStreamTrack]

    internal weak var memberRepresentation: RoomMemberRepresentation?
    internal var audioProcessCompletion: ((Double) -> Void)?

    init(renderer: PhenixRenderer, audioTracks: [PhenixMediaStreamTrack], queue: DispatchQueue) {
        self.queue = queue
        self.renderer = renderer
        self.audioTracks = audioTracks
    }

    func observeLevel() {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let track = self.audioTracks.first else { return }

            os_log(.debug, log: .roomMemberStreamAudioLevelProvider, "Observe audio level changes, (%{PRIVATE}s)", self.memberDescription)
            self.renderer.setFrameReadyCallback(track, self.didReceiveAudioFrame)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMemberStreamAudioLevelProvider, "Dispose, (%{PRIVATE}s)", self.memberDescription)

        for track in audioTracks {
            renderer.setFrameReadyCallback(track, nil)
        }
    }
}

private extension MemberStreamAudioLevelProvider {
    func process(_ sampleBuffer: CMSampleBuffer) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

            var totalLength = Int()
            var lengthAtOffset = Int()
            var dataPointer: UnsafeMutablePointer<Int8>?

            guard CMBlockBufferGetDataPointer(dataBuffer,
                                              atOffset: 0,
                                              lengthAtOffsetOut: &lengthAtOffset,
                                              totalLengthOut: &totalLength,
                                              dataPointerOut: &dataPointer) == kCMBlockBufferNoErr
                    && lengthAtOffset == totalLength else { return }

            guard let formatDescription: CMAudioFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
            guard let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else { return }

            guard (audioStreamBasicDescription.pointee.mFormatFlags & kAudioFormatFlagIsSignedInteger) == kAudioFormatFlagIsSignedInteger else {
                assertionFailure("FormatFlags is not a signed integer")
                return
            }

            guard audioStreamBasicDescription.pointee.mBitsPerChannel == 16 else {
                assertionFailure("Bits per channel is not equal to 16")
                return
            }

            self.handle16BitIntegerAudio(data: dataPointer, length: totalLength, description: audioStreamBasicDescription.pointee)
        }
    }

    func handle16BitIntegerAudio(data: UnsafeMutablePointer<Int8>?, length: Int, description: AudioStreamBasicDescription) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard let data = data else { return }

        let samples: [Int16] = convertSamples(data: data, length: length)
        let decibel = calculateDecibel(fromSamples: samples)

        audioProcessCompletion?(decibel)
    }

    func calculateDecibel(fromSamples samples: [Int16]) -> Double {
        dispatchPrecondition(condition: .onQueue(queue))

        guard !samples.isEmpty else { return Self.minimumDecibel }
        var normalizedMaxAmplitude: Double = 0

        if let maxPositive = samples.max() {
            normalizedMaxAmplitude = Double(maxPositive) / Double(Int16.max)
        }

        guard normalizedMaxAmplitude > 0 else { return Self.minimumDecibel }

        let calculatedDecibel = 20 * log10(normalizedMaxAmplitude)

        let decibel = max(calculatedDecibel, Self.minimumDecibel)

        return decibel
    }

    func convertSamples<T>(data: UnsafePointer<Int8>, length: Int) -> [T] {
        dispatchPrecondition(condition: .onQueue(queue))

        return data.withMemoryRebound(to: T.self, capacity: length / MemoryLayout<T>.stride) { pointer -> [T] in
            let buffer = UnsafeBufferPointer(start: pointer, count: length / MemoryLayout<T>.stride)
            return Array(buffer)
        }
    }
}

// MARK: - Observable callbacks
private extension MemberStreamAudioLevelProvider {
    func didReceiveAudioFrame(_ notification: PhenixFrameNotification?) {
        notification?.read { [weak self] sampleBuffer in
            guard let sampleBuffer = sampleBuffer else { return }

            self?.process(sampleBuffer)
        }
    }
}
