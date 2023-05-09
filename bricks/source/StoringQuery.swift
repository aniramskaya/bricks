//
//  StoringQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// ``FailableQuery`` which stores loaded data into a storage on success
public final class StoringQuery<WrappedQuery: FailableQuery, Storage: SynchronousStorage>: FailableQuery where Storage.Stored == WrappedQuery.Success
{
    public typealias Success = WrappedQuery.Success
    public typealias Failure = WrappedQuery.Failure
    public typealias Result = WrappedQuery.Result
    
    private var query: WrappedQuery
    private var storage: Storage
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - query: FailableQuery to wrap
    ///   - storage: Storage to save succesfully loaded data
    public init(query: WrappedQuery, storage: Storage) {
        self.query = query
        self.storage = storage
    }
    
    /// Loads data from `query` passed in initializer and if it succeeded stores it into `storage`
    /// 
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (WrappedQuery.Result) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            if let value = try? result.get() {
                self.storage.save(value)
            }
            completion(result)
        }
    }
}
