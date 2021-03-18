//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

struct MemberStreamSubscriptionProvider {
    let roomExpress: PhenixRoomExpress
    let stream: PhenixStream
    let options: PhenixSubscribeToMemberStreamOptions

    private func makeRenderer(from subscriber: PhenixExpressSubscriber) -> PhenixRenderer {
        subscriber.createRenderer()
    }

    func subscribe(completion: @escaping (Swift.Result<Result, Error>) -> Void) {
        roomExpress.subscribe(toMemberStream: stream, options) { status, subscriber, _ in
            switch status {
            case .ok:
                guard let subscriber = subscriber else {
                    fatalError("Subscriber is not provided.")
                }

                let renderer = makeRenderer(from: subscriber)
                let result = Result(subscriber: subscriber, renderer: renderer)

                completion(.success(result))

            default:
                let error = Error(reason: status.description)
                completion(.failure(error))
            }
        }
    }
}

extension MemberStreamSubscriptionProvider {
    struct Result {
        let subscriber: PhenixExpressSubscriber
        let renderer: PhenixRenderer
    }

    public struct Error: Swift.Error, LocalizedError {
        public let reason: String
        public var errorDescription: String? { reason }
    }
}
