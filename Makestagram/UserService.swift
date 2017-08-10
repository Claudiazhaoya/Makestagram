//
//  UserService.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/27/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

struct UserService {
    //insert user-related networking code here
    static func create(_ firUser: FIRUser, username: String, completion: @escaping (User?) -> Void) {
        let userAttrs: [String: Any] =  ["username": username,
                                         "follower_count": 0,
                                         "following_count" : 0,
                                         "post_count" : 0]
        
        let ref = Database.database().reference().child("users").child(firUser.uid)
        ref.setValue(userAttrs) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
        }
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let user = User(snapshot: snapshot)
            completion(user)
        })
        
    }
    
    static func show(forUID uid: String, completion: @escaping (User?) -> Void) {
        let ref = Database.database().reference().child("users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            
            completion(user)
        })
    }
    
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
        //construct a relative path to a location within our database
        let ref = DatabaseReference.toLocation(.posts(uid: user.uid))
        //read info from firebase database
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            let dispatchGroup = DispatchGroup()
            
            let posts: [Post] = snapshot.reversed().flatMap {
                guard let post = Post(snapshot: $0)
                    else { return nil }
                
                dispatchGroup.enter()
                
                LikeService.isPostLiked(post) { (isLiked) in
                    post.isLiked = isLiked
                    
                    dispatchGroup.leave()
                }
                
                return post
            }
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts)
            })
        })
    }
    
    static func usersExcludingCurrentUser(completion: @escaping ([User]) -> Void) {
        let currentUser = User.current
        // 1
        let ref = Database.database().reference().child("users")
        
        // 2
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            // 3
            let users =
                snapshot
                    .flatMap(User.init)
                    .filter { $0.uid != currentUser.uid }
            
            // 4
            let dispatchGroup = DispatchGroup()
            users.forEach { (user) in
                dispatchGroup.enter()
                
                // 5
                FollowService.isUserFollowed(user) { (isFollowed) in
                    user.isFollowed = isFollowed
                    dispatchGroup.leave()
                }
            }
            
            // 6
            dispatchGroup.notify(queue: .main, execute: {
                completion(users)
            })
        })
    }
    
    static func followers(for user: User, completion: @escaping ([String]) -> Void) {
        let followersRef = Database.database().reference().child("followers").child(user.uid)
        
        followersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followersDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            let followersKeys = Array(followersDict.keys)
            completion(followersKeys)
        })
    }
    //create user's timeline
    static func timeline(pageSize: UInt, lastPostKey: String? = nil, completion: @escaping ([Post]) -> Void) {
        
        let currentUser = User.current
        
        let ref = Database.database().reference().child("timeline").child(currentUser.uid)
        
        var query = ref.queryOrderedByKey().queryLimited(toLast: pageSize)
        if let lastPostKey = lastPostKey {
            query = query.queryEnding(atValue: lastPostKey)
        }
        
        
        query.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let dispatchGroup = DispatchGroup()
            
            var posts = [Post]()
            
            for postSnap in snapshot {
                guard let postDict = postSnap.value as? [String : Any],
                    let posterUID = postDict["poster_uid"] as? String
                    else { continue }
                
                dispatchGroup.enter()
                
                PostService.show(forKey: postSnap.key, posterUID: posterUID) { (post) in
                    if let post = post {
                        posts.append(post)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts.reversed())
            })
        })
    }
    
    //retrieve data to provide content for a given user's profile.
    static func observeProfile(for user: User, completion: @escaping (DatabaseReference, User?, [Post]) -> Void) -> DatabaseHandle {
        // 1 Create a reference to the location we want to read the user object from.
        let userRef = Database.database().reference().child("users").child(user.uid)
        
        // 2 Observer the DatabaseReference to retrieve the user object.
        return userRef.observe(.value, with: { snapshot in
            // 3 Check that the data returned is a valid user. If not, return an empty completion block.
            guard let user = User(snapshot: snapshot) else {
                return completion(userRef, nil, [])
            }
            
            // 4 Retrieve all posts for the respective user.
            posts(for: user, completion: { posts in
                // 5 Return the completion block with a reference to the DatabaseReference, user, and posts if successful.
                completion(userRef, user, posts)
            })
        })
    }
    
    static func following(for user: User = User.current, completion: @escaping ([User]) -> Void) {
        // 1 Create a reference to the location we want to read data from and retrieve the data
        let followingRef = Database.database().reference().child("following").child(user.uid)
        followingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // 2 Check that the the data we retrieve is the expected type
            guard let followingDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            // 3 Use dispatch groups to retrieve each user from their UID and build the array of following
            var following = [User]()
            let dispatchGroup = DispatchGroup()
            
            for uid in followingDict.keys {
                dispatchGroup.enter()
                
                UserService.show(forUID: uid) { user in
                    if let user = user {
                        following.append(user)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            // 4 return the array of following after all tasks of the dispatch group have been completed
            dispatchGroup.notify(queue: .main) {
                completion(following)
            }
        })
    }
    /*Create a reference to the user argument's chat data
    Observe the user's chat data for DataEventType.value. If the DataEventType is triggered, the completion handler is executed.*/
    static func observeChats(for user: User = User.current, withCompletion completion: @escaping (DatabaseReference, [Chat]) -> Void) -> DatabaseHandle {
        let ref = Database.database().reference().child("chats").child(user.uid)
        
        return ref.observe(.value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion(ref, [])
            }
            
            let chats = snapshot.flatMap(Chat.init)
            completion(ref, chats)
        })
    }
}
