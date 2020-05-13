//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

protocol CellIdentified { }

extension CellIdentified where Self: UITableViewCell {
    static var identifier: String { String(describing: self) }
}

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell & CellIdentified>(for indexPath: IndexPath) -> T {
        dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as! T
    }
}
