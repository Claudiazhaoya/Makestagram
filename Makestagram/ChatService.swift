//
//  ChatService.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/30/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseDatabase


struct ChatService {
    static func create(from message: Message, with chat: Chat, completion: @escaping (Chat?) -> Void) {
        
        // 1 we create a dictionary of each member's UID. We do this to easily each member's UID in JSON
        var membersDict = [String : Bool]()
        for uid in chat.memberUIDs {
            membersDict[uid] = true
        }
        
        // 2 Populate our Chat object with missing data from the first message sent.
        let lastMessage = "\(message.sender.username): \(message.content)"
        chat.lastMessage = lastMessage
        let lastMessageSent = message.timestamp.timeIntervalSince1970
        chat.lastMessageSent = message.timestamp
        
        // 3 Create a dictionary of the chat JSON object to be stored in our database
        let chatDict: [String : Any] = ["title" : chat.title,
                                        "memberHash" : chat.memberHash,
                                        "members" : membersDict,
                                        "lastMessage" : lastMessage,
                                        "lastMessageSent" : lastMessageSent]
        
        // 4 Generate a location for a new child node for the chat object.
        let chatRef = Database.database().reference().child("chats").child(User.current.uid).childByAutoId()
        chat.key = chatRef.key
        
        // 5 Create a multi-location update dictionary. This will allow us to write to multiple locations without needing to make multiple API requests.
        var multiUpdateValue = [String : Any]()
        
        // 6 Update each of the chat member's chats with the denormalized chat JSON object.
        for uid in chat.memberUIDs {
            multiUpdateValue["chats/\(uid)/\(chatRef.key)"] = chatDict
        }
        
        // 7 Create a new DatabaseReference for a new messages child node.
        let messagesRef = Database.database().reference().child("messages").child(chatRef.key).childByAutoId()
        let messageKey = messagesRef.key
        
        // 8
        multiUpdateValue["messages/\(chatRef.key)/\(messageKey)"] = message.dictValue
        
        // 9
        let rootRef = Database.database().reference()
        rootRef.updateChildValues(multiUpdateValue) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            }
            
            completion(chat)
        }
    }
    
    static func checkForExistingChat(with user: User, completion: @escaping (Chat?) -> Void) {
        // 1 Get the hash value from each of the member's UIDs using the hashing class method from Chat
        let members = [user, User.current]
        let hashValue = Chat.hash(forMembers: members)
        
        // 2 Create a reference to the current user's chat data to check for an existing chat with the other member
        let chatRef = Database.database().reference().child("chats").child(User.current.uid)
        
        // 3 Construct a query for a matching memberHash child value of each chat JSON object.
        let query = chatRef.queryOrdered(byChild: "memberHash").queryEqual(toValue: hashValue)
        
        // 4 Return the corresponding Chat if it exists.
        query.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let chatSnap = snapshot.children.allObjects.first as? DataSnapshot,
                let chat = Chat(snapshot: chatSnap)
                else { return completion(nil) }
            
            completion(chat)
        })
    }
    
    static func sendMessage(_ message: Message, for chat: Chat, success: ((Bool) -> Void)? = nil) {
        guard let chatKey = chat.key else {
            success?(false)
            return
        }
        
        var multiUpdateValue = [String : Any]()
        
        for uid in chat.memberUIDs {
            let lastMessage = "\(message.sender.username): \(message.content)"
            multiUpdateValue["chats/\(uid)/\(chatKey)/lastMessage"] = lastMessage
            multiUpdateValue["chats/\(uid)/\(chatKey)/lastMessageSent"] = message.timestamp.timeIntervalSince1970
        }
        
        let messagesRef = Database.database().reference().child("messages").child(chatKey).childByAutoId()
        let messageKey = messagesRef.key
        multiUpdateValue["messages/\(chatKey)/\(messageKey)"] = message.dictValue
        
        let rootRef = Database.database().reference()
        rootRef.updateChildValues(multiUpdateValue, withCompletionBlock: { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                success?(false)
                return
            }
            
            success?(true)
        })
    }
    
    static func observeMessages(forChatKey chatKey: String, completion: @escaping (DatabaseReference, Message?) -> Void) -> DatabaseHandle {
        let messagesRef = Database.database().reference().child("messages").child(chatKey)
        
        return messagesRef.observe(.childAdded, with: { snapshot in
            guard let message = Message(snapshot: snapshot) else {
                return completion(messagesRef, nil)
            }
            
            completion(messagesRef, message)
        })
    }
}
