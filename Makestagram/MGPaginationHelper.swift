//
//  MGPaginationHelper.swift
//  Makestagram
//
//  Created by Zhaoya Sun on 6/29/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation

protocol MGKeyed {
    var key: String? { get set }
}

class MGPaginationHelper<T: MGKeyed> {
    enum MGPaginationState {
        case initial //no data has been loaded yet
        case ready  //ready and waiting for next request to paginate and load the next page
        case loading //currently paginating and waiting for data from Firebase
        case end //all data has been paginated
    }
    
    // MARK: - Properties
    
    let pageSize: UInt //Determines the number of posts that will be on each page.
    let serviceMethod: (UInt, String?, @escaping (([T]) -> Void)) -> Void //The service method that will return paginated data.
    var state: MGPaginationState = .initial //The current pagination state of the helper.
    var lastObjectKey: String? //Firebase uses object keys to determine the last position of the page. We'll need to use this as an offset for paginating.
    
    // MARK: - Init
    
    init(pageSize: UInt = 3, serviceMethod: @escaping (UInt, String?, @escaping (([T]) -> Void)) -> Void) {
        self.pageSize = pageSize
        self.serviceMethod = serviceMethod
    }
    
    // 1
    func paginate(completion: @escaping ([T]) -> Void) {
        // 2
        switch state {
        // 3
        case .initial:
            lastObjectKey = nil
            fallthrough
            
        // 4
        case .ready:
            state = .loading
            serviceMethod(pageSize, lastObjectKey) { [unowned self] (objects: [T]) in
                // 5
                defer {
                    // 6
                    if let lastObjectKey = objects.last?.key {
                        self.lastObjectKey = lastObjectKey
                    }
                    
                    // 7
                    self.state = objects.count < Int(self.pageSize) ? .end : .ready
                }
                
                // 8
                guard let _ = self.lastObjectKey else {
                    return completion(objects)
                }
                
                // 9
                let newObjects = Array(objects.dropFirst())
                completion(newObjects)
            }
            
        // 10
        case .loading, .end:
            return
        }
    }
    func reloadData(completion: @escaping ([T]) -> Void) {
        state = .initial
        
        paginate(completion: completion)
    }
}
