//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Denis Yaremenko on 25.01.2025.
//

import Foundation

/// Высокоуровневый модуль — это бизнес-логика, не зависящая от деталей реализации хранилища.
/// business logic
///
public final class LocalFeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    private let maxCacheAgeInDays: Int = 7
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
                
            case let .failure(error):
                self.store.deleteCachedFeed(completion: { _ in })
                completion(.failure(error))
                
                // found but not valid
            case .found:
                self.store.deleteCachedFeed(completion: { _ in })
                completion(.success([]))
                
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return currentDate() < maxCacheAge
    }
}

private extension Array where Element == FeedImage {
    
    func toLocal() -> [LocalFeedImage] {
        map {
            LocalFeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
    }
}

private extension Array where Element == LocalFeedImage {
    
    func toModels() -> [FeedImage] {
        map {
            FeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
    }
}
