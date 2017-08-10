//
//  CreateUsernameViewController.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/26/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase

class CreateUserViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        //1 check if a FIRUser is logged in and if a username in the text field
        guard let firUser = Auth.auth().currentUser, let username = usernameTextField.text, !username.isEmpty else {
            return
        }
        
        UserService.create(firUser, username: username) {
            (user) in
            guard let user = user else {
                return
            }
            
            User.setCurrent(user, writeToUserDefaults: true)
            
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            if let initialViewCOntroller = storyboard.instantiateInitialViewController() {
                self.view.window?.rootViewController = initialViewCOntroller
                self.view.window?.makeKeyAndVisible()
            }
            
        }
        //create a new instance of our main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        //check that the storyboard has an initial view controller
        if let initialViewController = storyboard.instantiateInitialViewController() {
            self.view.window?.rootViewController = initialViewController
            self.view.window?.makeKeyAndVisible()
        }
    }
    
}
