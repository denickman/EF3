//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Denis Yaremenko on 25.01.2025.
//

import Foundation

// (abstraction)
public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
}

