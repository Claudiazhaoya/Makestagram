//
//  Post.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase.FIRDataSnapshot



class Post: MGKeyed {
    var key: String?
    let imageURL: String
    let imageHeight: CGFloat
    let creationDate: Date
    var likeCount: Int
    let poster: User
    var isLiked: Bool
    
    init(imageURL: String, imageHeight: CGFloat) {
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date()
        self.likeCount = 0
        self.poster = User.current
        self.isLiked = false
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let imageURL = dict["image_url"] as? String,
            let imageHeight = dict["image_height"] as? CGFloat,
            let createdAgo = dict["created_at"] as? TimeInterval,
            let likeCount = dict["like_count"] as? Int,
            let userDict = dict["poster"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String,
            let isLiked = userDict["is_liked"] as? Bool
            else { return nil }
    
        self.key = snapshot.key
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
        self.likeCount = likeCount
        self.poster = User(uid: uid, username: username)
        self.isLiked = isLiked
    }
    
    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict: [String : Any] = ["uid" : poster.uid,
                        "username" : poster.username,
                        "is_liked": isLiked]
        return ["image_url" : imageURL,
                "image_height" : imageHeight,
                "created_at" : createdAgo,
                "like_count": likeCount,
                "poster": userDict]
    }
    
}
