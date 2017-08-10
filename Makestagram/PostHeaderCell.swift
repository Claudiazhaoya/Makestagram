//
//  PostHeaderCell.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit

class PostHeaderCell: UITableViewCell {
    static let height: CGFloat = 54
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    @IBAction func optionButtonTapped(_ sender: UIButton) {
        print("options button tapped")
    }
}
