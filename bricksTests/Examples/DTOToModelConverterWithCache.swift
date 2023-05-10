//
//  DTOToModelConverterWithCache.swift
//  bricksTests
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation
import XCTest
import bricks

struct DTO: Encodable {
    let value: UUID
}

extension DTO {
    static func toModel(_ result: Result<DTO, Error>) -> Result<Model, Error> {
        result.map { Model(value: $0.value.uuidString) }
    }
}

struct Model: Equatable {
    let value: String
}

class DTOLoader: FailableQuery {
    typealias Success = DTO
    typealias Failure = Swift.Error
    
    let dto: DTO
    init(dto: DTO) {
        self.dto = dto
    }
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        completion(.success(dto))
    }
}

class DTOToModelConverterWithCache: XCTestCase {
    func test_dtoIsConvertedToModel() throws {
        let (dto, model) = matchingDTOAndModel()
        let sut = DTOLoader(dto: dto).convert(map: DTO.toModel)

        expect(sut: sut, toCompleteWith: .success(model))
    }
    
    func test_modelIsStored() throws {
        let (dto, model) = matchingDTOAndModel()
        let storage = InMemoryStorage<Model>().adapted()
        
        let sut = DTOLoader(dto: dto)
        .convert(map: DTO.toModel)
        .storing(into: storage)
        
        expect(sut: sut, toCompleteWith: .success(model))

        storage.load { result in
            XCTAssertEqual(try? result.get(), model)
        }
    }
    
    private func matchingDTOAndModel() -> (DTO, Model) {
        let uuid = UUID()
        let dto = DTO(value: uuid)
        let model = Model(value: uuid.uuidString)

        return (dto, model)
    }
    
    private func expect<SUT: FailableQuery>(sut: SUT, toCompleteWith expectedResult: Result<Model, Error>, file: StaticString = #filePath, line: UInt = #line) where SUT.Success == Model, SUT.Failure == Error {
        
        let exp = expectation(description: "Wait for async query to complete")
        sut.load { (result: Result<Model, Error>) in
            switch (result, expectedResult) {
            case let (.success(received), .success(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            case let (.failure(received), .failure(expected)):
                XCTAssertEqual(received as NSError, expected as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

}

class TimeIntervalValidationPolicy: TimestampValidationPolicy {
    func validate(_: Date?) -> Bool {
        return true
    }
}
