//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

protocol Storyboarded {
    static func instantiate(from board: UIStoryboard) -> Self
}

extension Storyboarded where Self: UIViewController {
    static func instantiate(from board: UIStoryboard = .main) -> Self {
        let id = String(describing: self)
        return board.instantiateViewController(withIdentifier: id) as! Self
    }
}

extension UIStoryboard {
    static let main = UIStoryboard(name: "Main", bundle: .main)
}
