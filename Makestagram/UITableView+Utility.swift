//
//  UITableView+Utility.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/29/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit

protocol CellIdentifiable {
    static var cellIdentifier: String { get }
}
// 1 create an extension on our protocol CellIdentifiable. In our extension, we can define default values for our protocol properties and functions
extension CellIdentifiable where Self: UITableViewCell {
    // 2 prevents us from making typos when typing out the cell identifier as a String
    static var cellIdentifier: String {
        return String(describing: self)
    }
}
// 3 allow us to define constraints on our generic that we'll learn about next.
extension UITableViewCell: CellIdentifiable { }

extension UITableView {
    // 1 We define a generic function that extensions UITableView
    func dequeueReusableCell<T: UITableViewCell>() -> T where T: CellIdentifiable {
        // 2
        guard let cell = dequeueReusableCell(withIdentifier: T.cellIdentifier) as? T else {
            // 3
            fatalError("Error dequeuing cell for identifier \(T.cellIdentifier)")
        }
        
        return cell
    }
}
