//
//  Converter.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// ``Query`` which loads data using another ``Query`` and then converts the result to a **Target** type
public class Converter<SourceQuery, Target>: Query where SourceQuery: Query
{
    /// A closure which converts ``Query/Result`` to a **Target** type
    public typealias TargetMapper = (SourceQuery.Result) -> Target
    
    private let query: SourceQuery
    private let map: TargetMapper
    
    /// Creates Converter with query and mapper
    /// - Parameters:
    ///   - query: An entity implementing ``Query`` protocol
    ///   - map: A closure to convert the loaded data from ``Query/Result`` to a **Target** type
    public init(query: SourceQuery, map: @escaping TargetMapper) {
        self.query = query
        self.map = map
    }
    
    /// Loads data using ``Query`` passed in ``init(query:map:)`` and then converts the result to a **Target** type using map closure.
    ///
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (Target) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            completion(self.map(result))
        }
    }
}

/// ``Converter`` subclass which conforms fo ``FailableQuery``
public class FailableConverter<SourceQuery, Success, Failure: Error>: Converter<SourceQuery, Result<Success, Failure>>, FailableQuery
where SourceQuery: Query { }


public extension Query {
    /// Wraps ``Query`` with ``Converter``
    ///
    /// This method is useful for chained composition
    func convert<Source, Target>(map: @escaping (Source) -> Target) -> Converter<Self, Target> where Source == Result {
        Converter(query: self, map: map)
    }
    
    /// Wraps ``Query`` with ``FailableConverter`` if  it matches <doc:/documentation/bricks/Query/Result> type requirements
    ///
    /// This method is useful for chained composition
    func map<Source, Success, Failure: Error>(with map: @escaping (Source) -> Swift.Result<Success, Failure>) -> FailableConverter<Self, Success, Failure> where Source == Result  {
        FailableConverter(query: self, map: map)
    }
}
