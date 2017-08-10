//
//  StorageReference+Post.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseStorage

typealias FIRStorageReference = FirebaseStorage.StorageReference

extension FIRStorageReference {
    static let dateFormatter = ISO8601DateFormatter()
    
    static func newPostImageReference() -> FIRStorageReference {
        let uid = User.current.uid
        let timestamp = dateFormatter.string(from: Date())
        
        return Storage.storage().reference().child("images/posts/\(uid)/\(timestamp).jpg")
    }
}
