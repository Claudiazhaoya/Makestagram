//
//  ChatViewController.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 7/2/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import FirebaseDatabase

class ChatViewController: JSQMessagesViewController {
    var messages = [Message]()
    var messagesHandle: DatabaseHandle = 0
    var messagesRef: DatabaseReference?
    var outgoingBubbleImageView: JSQMessagesBubbleImage = {
        guard let bubbleImageFactory = JSQMessagesBubbleImageFactory() else {
            fatalError("Error creating bubble image factory.")
        }
        
        let color = UIColor.jsq_messageBubbleBlue()
        return bubbleImageFactory.outgoingMessagesBubbleImage(with: color)
    }()
    
    var incomingBubbleImageView: JSQMessagesBubbleImage = {
        guard let bubbleImageFactory = JSQMessagesBubbleImageFactory() else {
            fatalError("Error creating bubble image factory.")
        }
        
        let color = UIColor.jsq_messageBubbleLightGray()
        return bubbleImageFactory.incomingMessagesBubbleImage(with: color)
    }()

    // MARK: - Properties
    
    var chat: Chat!
    
    // MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupJSQMessagesViewController()
        tryObservingMessages()
    }
    
    deinit {
        messagesRef?.removeObserver(withHandle: messagesHandle)
    }
    
    func setupJSQMessagesViewController() {
        // 1. identify current user
        senderId = User.current.uid
        senderDisplayName = User.current.username
        title = chat.title
        
        // 2. remove attachment button
        inputToolbar.contentView.leftBarButtonItem = nil
        
        // 3. remove avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
}
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - JSQMessagesCollectionViewDataSource

extension ChatViewController {
    // 1
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // 2
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // 3
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item].jsqMessageValue
    }
    
    // 4
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let sender = message.sender
        
        if sender.uid == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    // 5
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.item]
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        cell.textView?.textColor = (message.sender.uid == senderId) ? .white : .black
        return cell
    }
    // check that the chat exists in our database by checking for the chat's key property.
    func tryObservingMessages() {
        guard let chatKey = chat?.key else { return }
        
        messagesHandle = ChatService.observeMessages(forChatKey: chatKey, completion: { [weak self] (ref, message) in
            self?.messagesRef = ref
            
            if let message = message {
                self?.messages.append(message)
                self?.finishReceivingMessage()
            }
        })
    }
}

// MARK: - Send Message

extension ChatViewController {
    func sendMessage(_ message: Message) {
        // 1  we check if the chat already exists in our database.
        if chat?.key == nil {
            // 2 Create the chat using the appropriate service method
            ChatService.create(from: message, with: chat, completion: { [weak self] chat in
                guard let chat = chat else { return }
                
                self?.chat = chat
                
                // 3  if creating the chat is successful, we'll call tryObservingMessages on our new chat object.
                self?.tryObservingMessages()
            })
        } else {
            // 4 If the chat already exists, we'll just update our database with our new message.
            ChatService.sendMessage(message, for: chat)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // 1 Create a new Message object using the text typed in by the current user.
        let message = Message(content: text)
        // 2 Write the message to our realtime database using our sendMessage(_:) method.
        sendMessage(message)
        // 3 Notify the JSQMessagesViewController that we've finished sending the messages
        finishSendingMessage()
        
        // 4 Play a sound to let the user know the message has been sent.
        JSQSystemSoundPlayer.jsq_playMessageSentAlert()
    }
}

// MARK: - UITableViewDelegate

extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toChat", sender: self)
    }
}

// MARK: - Navigation

extension ChatListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "toChat",
            let destination = segue.destination as? ChatViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            
            destination.chat = chats[indexPath.row]
        }
    }
}
