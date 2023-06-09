//
//  InMemoryCacheTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class SynchronousStorageTests: XCTestCase {
    func test_load_deliversNilFromEmptyStorage() {
        let sut = InMemoryStorage<String>()
        
        XCTAssertNil(sut.load())
        XCTAssertNil(sut.timestamp)
    }
    
    func test_load_hasNoSideEffectsOnEmptyStorage() {
        let sut = InMemoryStorage<String>()
        
        XCTAssertNil(sut.load())
        XCTAssertNil(sut.timestamp)
        XCTAssertNil(sut.load())
        XCTAssertNil(sut.timestamp)
    }

    func test_load_deliversStoredValueFromNonEmptyStorage() {
        let sut = InMemoryStorage<String>()
        let value = UUID().uuidString
        
        sut.save(value)
        
        XCTAssertEqual(sut.load(), value)
        XCTAssertNotNil(sut.timestamp)
    }
    
    func test_load_hasNoSideEffectsOnNonEmptyStorage() {
        let sut = InMemoryStorage<String>()
        let value = UUID().uuidString
        
        sut.save(value)
        
        XCTAssertEqual(sut.load(), value)
        let timestamp1 = sut.timestamp
        XCTAssertEqual(sut.load(), value)
        let timestamp2 = sut.timestamp
        XCTAssertEqual(timestamp1, timestamp2)
    }

    func test_save_replacesPreviousValue() {
        let sut = InMemoryStorage<String>()
        let value1 = UUID().uuidString
        let value2 = UUID().uuidString

        sut.save(value1)
        XCTAssertEqual(sut.load(), value1)

        
        sut.save(value2)
        XCTAssertEqual(sut.load(), value2)
    }

    func test_save_replacesTimestamp() {
        let sut = InMemoryStorage<String>()
        let value1 = UUID().uuidString
        let value2 = UUID().uuidString

        XCTAssertNil(sut.timestamp)
        
        sut.save(value1)
        let timestamp1 = sut.timestamp
        RunLoop.main.run(until: Date())
        
        sut.save(value2)
        let timestamp2 = sut.timestamp
        
        XCTAssertNotNil(timestamp1)
        XCTAssertNotNil(timestamp2)
        XCTAssertNotEqual(timestamp1, timestamp2)
    }

    func test_clear_deletesStoredValue() {
        let sut = InMemoryStorage<String>()
        let value = UUID().uuidString

        sut.save(value)
        XCTAssertEqual(sut.load(), value)
        XCTAssertNotNil(sut.timestamp)

        
        sut.clear()
        XCTAssertNil(sut.load())
        XCTAssertNil(sut.timestamp)
    }
}
