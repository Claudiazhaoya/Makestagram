//
//  MainTabBarController.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/27/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    let photoHelper = MGPhotoHelper()
    override func viewDidLoad() {
        super.viewDidLoad()
        //we will implement the photo upload later on.
        photoHelper.completionHandler = { image in
            PostService.create(for: image)
        }
        // 1
        delegate = self
        // 2
        tabBar.unselectedItemTintColor = .black
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 1 {
            photoHelper.presentActionSheet(from: self)
            return false
        } else {
            return true
        }
    }
}
