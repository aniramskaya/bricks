//
//  InMemoryStorage.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

///  Synchronous storage. Stores a value synchronously on the thread it was called from.
public protocol SynchronousStorage {
    associatedtype Stored
    
    /// Retrieves stored value
    func load() -> Stored?
    
    /// Saves value
    func save(_: Stored)
    
    /// Removes stored value, if any
    func clear()
}

/// In-memory storage simply holds the data passed into `load` method
public class InMemoryStorage<Stored>: SynchronousStorage {
    private var stored: Stored?
    
    public init() {}
    
    /// Retrieves stored value overriding the previous one
    public func load() -> Stored? { return stored }
    public func save(_ value: Stored) { stored = value }
    public func clear() { stored = nil }
}