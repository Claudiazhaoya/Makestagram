//
//  FollowService.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/28/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FollowService {
    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : true,
                          "following/\(currentUID)/\(user.uid)" : true]
        
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                success(false)
            }
            
            // 1
            UserService.posts(for: user) { (posts) in
                // 2
                let postKeys = posts.flatMap { $0.key }
                
                // 3
                var followData = [String : Any]()
                let timelinePostDict = ["poster_uid" : user.uid]
                postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                
                // 4
                ref.updateChildValues(followData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                        success(false)
                    }
                    
                    // 1 created a dispatch group to manage the completion of asynchronous requests
                    let dispatchGroup = DispatchGroup()
                    
                    // 2 Each time we make a request,  we'll tracking the completion of incrementing the following_count
                    dispatchGroup.enter()
                    
                    // 3 create a reference to the location of the following_count that we want to increment and use transaction operations to increment the count.
                    let followingCountRef = Database.database().reference().child("users").child(currentUID).child("following_count")
                    followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                        // 4 Boilerplate logic for incrementing a count using Firebase transaction blocks
                        let currentCount = mutableData.value as? Int ?? 0
                        mutableData.value = currentCount + 1
                        
                        return TransactionResult.success(withValue: mutableData)
                    })
                    
                    // 5 for current user
                    dispatchGroup.enter()
                   
                    // 6
                    let followerCountRef = Database.database().reference().child("users").child(user.uid).child("follower_count")
                    followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                        let currentCount = mutableData.value as? Int ?? 0
                        mutableData.value = currentCount + 1
                        
                        return TransactionResult.success(withValue: mutableData)
                    })
                    
                    // 6
                    dispatchGroup.enter()
                    UserService.posts(for: user) { (posts) in
                        let postKeys = posts.flatMap { $0.key }
                        
                        var followData = [String : Any]()
                        let timelinePostDict = ["poster_uid" : user.uid]
                        postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                        
                        ref.updateChildValues(followData, withCompletionBlock: { (error, ref) in
                            if let error = error {
                                assertionFailure(error.localizedDescription)
                            }
                            
                            dispatchGroup.leave()
                        })
                    }
                    
                    // 7
                    dispatchGroup.notify(queue: .main) {
                        success(true)
                    }
                    
                    // 5
                    success(error == nil)
                })
            }
        }
    }
    
    private static func unfollowUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
        // http://stackoverflow.com/questions/38462074/using-updatechildvalues-to-delete-from-firebase
        let followData = ["followers/\(user.uid)/\(currentUID)" : NSNull(),
                          "following/\(currentUID)/\(user.uid)" : NSNull()]
        
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            UserService.posts(for: user, completion: { (posts) in
                var unfollowData = [String : Any]()
                let postsKeys = posts.flatMap { $0.key }
                postsKeys.forEach {
                    // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
                    unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
                }
                
                ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                        return success(false)
                    }
                    
                    let dispatchGroup = DispatchGroup()
                    
                    dispatchGroup.enter()
                    let followingCountRef = Database.database().reference().child("users").child(currentUID).child("following_count")
                    followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                        let currentCount = mutableData.value as? Int ?? 0
                        mutableData.value = currentCount - 1
                        
                        return TransactionResult.success(withValue: mutableData)
                    })
                    
                    dispatchGroup.enter()
                    let followerCountRef = Database.database().reference().child("users").child(user.uid).child("follower_count")
                    followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                        let currentCount = mutableData.value as? Int ?? 0
                        mutableData.value = currentCount - 1
                        
                        return TransactionResult.success(withValue: mutableData)
                    })
                    
                    dispatchGroup.enter()
                    UserService.posts(for: user, completion: { (posts) in
                        var unfollowData = [String : Any]()
                        let postsKeys = posts.flatMap { $0.key }
                        postsKeys.forEach {
                            // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
                            unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
                        }
                        
                        ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                            if let error = error {
                                assertionFailure(error.localizedDescription)
                            }
                            
                            dispatchGroup.leave()
                        })
                    })
                    
                    dispatchGroup.notify(queue: .main) {
                        success(true)
                    }
                    
                    success(error == nil)
                })
            })
        }
    }
    
    static func setIsFollowing(_ isFollowing: Bool, fromCurrentUserTo followee: User, success: @escaping (Bool) -> Void) {
        if isFollowing {
            followUser(followee, forCurrentUserWithSuccess: success)
        } else {
            unfollowUser(followee, forCurrentUserWithSuccess: success)
        }
    }
    
    static func isUserFollowed(_ user: User, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let ref = Database.database().reference().child("followers").child(user.uid)
        
        ref.queryEqual(toValue: nil, childKey: currentUID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String : Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
   //fetch data from firebase
    static func show(forKey postKey: String, posterUID: String, completion: @escaping (Post?) -> Void) {
        let ref = Database.database().reference().child("posts").child(posterUID).child(postKey)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let post = Post(snapshot: snapshot) else {
                return completion(nil)
            }
            
            LikeService.isPostLiked(post) { (isLiked) in
                post.isLiked = isLiked
                completion(post)
            }
        })
    }
}
