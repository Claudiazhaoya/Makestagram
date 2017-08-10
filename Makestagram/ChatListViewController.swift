//
//  ChatListViewController.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/30/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class ChatListViewController: UIViewController {
    
    //properties
    var chats = [Chat]()
    
   
    // MARK: - VC Lifecycle
    
    // 1 First we create two properties to store reference to the DatabaseHandle and DatabaseReference. We'll need this to clean up and stop observing data when the view controller is dismissed.
    var userChatsHandle: DatabaseHandle = 0
    var userChatsRef: DatabaseReference?
    
    @IBOutlet weak var tableView: UITableView!
    // MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 71
        // remove separators for empty cells
        tableView.tableFooterView = UIView()
        
        // 2 observe the current user's chats.
        userChatsHandle = UserService.observeChats { [weak self] (ref, chats) in
            self?.userChatsRef = ref
            self?.chats = chats
            
            // 3 Once the completion handler is executed, we make sure we update the UI on the main thread.
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    deinit {
        // 4 when we dispose of the view controller, we manually remove the observer.
        userChatsRef?.removeObserver(withHandle: userChatsHandle)
    }
   
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
}

extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        
        let chat = chats[indexPath.row]
        cell.titleLabel.text = chat.title
        cell.lastMessageLabel.text = chat.lastMessage
        
        return cell
    }
}
