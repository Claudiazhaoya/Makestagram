//
//  ProfileHeaderView.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/30/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit

protocol ProfileHeaderViewDelegate: class {
    func didTapSettingsButton(_ button: UIButton, on headerView: ProfileHeaderView)
}

class ProfileHeaderView: UICollectionReusableView {
    
    // MARK: - Properties
    weak var delegate: ProfileHeaderViewDelegate?
    
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        settingsButton.layer.cornerRadius = 6
        settingsButton.layer.borderColor = UIColor.lightGray.cgColor
        settingsButton.layer.borderWidth = 1
    }

    @IBAction func settingsButtonTapped(_ sender: UIButton) {
         delegate?.didTapSettingsButton(sender, on: self)
    }
    
}
