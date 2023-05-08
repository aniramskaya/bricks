//
//  ExpirableCache.swift
//  bricksTests
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation
import XCTest
import bricks

class ExpirableCacheTests: XCTestCase {
    func test_cache_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_deliversErrorOnExpiredCache() throws {
        let (sut, spy) = makeSUT()
        spy.isValid = false
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .failure(ExpirableCache.Error.expired))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }

    func test_load_deliversErrorOnEmptyCache() throws {
        let (sut, spy) = makeSUT()
        spy.isValid = true
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .failure(ExpirableCache.Error.empty))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }

    func test_load_deliversSuccessOnNonExpiredCache() throws {
        let (sut, spy) = makeSUT()
        let value = UUID().uuidString
        spy.value = value
        spy.isValid = true
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .success(value))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }
    
    private func makeSUT() -> (ExpirableCache<StorageSpy>, StorageSpy) {
        let spy = StorageSpy()
        let sut = ExpirableCache<StorageSpy>(storage: spy, validationPolicy: spy)

        trackForMemoryLeaks(spy)
        trackForMemoryLeaks(sut)
        return (sut, spy)
    }

    private func expect(sut: ExpirableCache<StorageSpy>, toCompleteWith expectedResult: Result<String, ExpirableCache<StorageSpy>.Error>, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for async query to complete")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(received), .success(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            case let (.failure(received), .failure(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

}

private class StorageSpy: SynchronousStorage, TimestampValidationPolicy {
    typealias Stored = String
    
    enum Message: Equatable {
        case load
        case save(String)
        case clear
        case validate(Date?)
    }
    
    var messages: [Message] = []
    
    var timestamp: Date?
    var value: String?
    
    func load() -> String? {
        messages.append(.load)
        return value
    }
    
    func save(_ value: String) {
        messages.append(.save(value))
        self.value = value
    }
    
    func clear() {
        messages.append(.clear)
        value = nil
    }
    
    var isValid = true
    func validate(_ timestamp: Date?) -> Bool {
        messages.append(.validate(timestamp))
        return isValid
    }
}
