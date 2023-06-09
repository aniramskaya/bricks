//
//  Loader.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// An abstraction which declares asynchronous load for any data
///
/// This protocol is the core of ``bricks``. Many classes conform to it or its descendants so it works like a glue making possible for them to operate together.
public protocol Query {
    /// Type of data to be loaded
    associatedtype Result

    /// Loads **Result** in an asynchronous manner with completion
    ///
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    func load(completion: @escaping (Result) -> Void)
}
