//
//  User.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/26/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot
import UIKit

class User: NSObject {
    
    typealias FIRDataSnapshot = FirebaseDatabase.DataSnapshot
    //1
    private static var _current: User?
    // 2 create a computed variable that only has a getter that can access the private _current variable
    static var current: User {
        // 3
        guard let currentUser = _current else {
            fatalError("Error: current user doesn't exist")
        }
        
        // 4
        return currentUser
    }
    
    // MARK: - Class Methods
    
    // 5 create a custom setter method to set the current user
    class func setCurrent(_ user: User, writeToUserDefaults: Bool = false) {
        // 2
        if writeToUserDefaults {
            // 3 turn our object into Data
            let data = NSKeyedArchiver.archivedData(withRootObject: user)
            
            // 4 We store the data for our current user with the correct key in UserDefaults.
            UserDefaults.standard.set(data, forKey: Constants.UserDefaults.currentUser)
        }
        
        _current = user
    }
    
    //Mark: - Properties
    let uid: String
    let username: String
    var isFollowed = false
    var followerCount: Int?
    var followingCount: Int?
    var postCount: Int?
    
    //Mark: - Init
    
    init(uid: String, username: String) {
        self.uid = uid
        self.username = username
        super.init()
    }
    
    init?(snapshot: FIRDataSnapshot) {
        guard let dict = snapshot.value as? [String: Any], let username = dict["username"] as? String,
            let followerCount = dict["follower_count"] as? Int,
            let followingCount = dict["following_count"] as? Int,
            let postCount = dict["post_count"] as? Int else {
            return nil
        }
        
        self.uid = snapshot.key
        self.username = username
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let uid = aDecoder.decodeObject(forKey: Constants.UserDefaults.uid) as? String,
            let username = aDecoder.decodeObject(forKey: Constants.UserDefaults.username) as? String
            else { return nil }
        
        self.uid = uid
        self.username = username
        
        super.init()
    }
}

extension User: NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: Constants.UserDefaults.uid)
        aCoder.encode(username, forKey: Constants.UserDefaults.username)
    }
}

