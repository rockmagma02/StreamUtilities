// Copyright 2024-2024 Ruiyang Sun. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@testable import SyncStream
import XCTest

final class SyncStreamTests: XCTestCase {
    func testSyncStreamWithElements() {
        let elements = [1, 2, 3]
        var index = 0
        let stream = SyncStream<Int> { continuation in
            for element in elements {
                continuation.yield(element)
            }
            continuation.finish()
            XCTAssertTrue(continuation.isFinished)
        }

        for element in stream {
            XCTAssertEqual(element, elements[index])
            index += 1
        }

        XCTAssertEqual(index, elements.count)
        XCTAssertNil(stream.next())
    }

    func testSyncStreamFinishWithoutElements() {
        let stream = SyncStream<Int> { continuation in
            continuation.finish()
        }

        XCTAssertNil(stream.next())
    }

    func testSyncStreamUnfolding() {
        let elements = [1, 2, 3]
        var index = 0
        let stream = SyncStream(unfolding: { index < elements.count ? elements[index] : nil })

        for element in stream {
            XCTAssertEqual(element, elements[index])
            index += 1
        }

        XCTAssertEqual(index, elements.count)
    }

    func testSyncStreamContainsElement() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }

        let stream2 = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertTrue(stream.contains(1))
        XCTAssertFalse(stream2.contains(3))
    }

    func testSyncStreamContainsClousure() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertTrue(stream.contains { $0 % 2 == 0 })

        let stream2 = SyncStream<Int> { continuation in
            continuation.yield(4)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertFalse(stream2.contains { $0 % 2 != 0 })
    }

    func testSyncStreamAllSatisfyCondition() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(2)
            continuation.yield(4)
            continuation.finish()
        }
        XCTAssertTrue(stream.allSatisfy { $0 % 2 == 0 })

        let stream2 = SyncStream<Int> { continuation in
            continuation.yield(2)
            continuation.yield(4)
            continuation.finish()
        }
        XCTAssertFalse(stream2.allSatisfy { $0 % 2 != 0 })
    }

    func testSyncStreamFirstWhere() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        XCTAssertEqual(stream.first { $0 > 1 }, 2)
        XCTAssertNil(stream.first { $0 > 3 })
    }

    func testSyncStreamMinAndMax() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(3)
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertEqual(stream.min(), 1)

        let stream2 = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(3)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertEqual(stream2.max(), 3)
    }

    func testSyncStreamMinAndMaxWithClousure() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(3)
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertEqual(stream.min(by: <), 1)

        let stream2 = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(3)
            continuation.yield(2)
            continuation.finish()
        }
        XCTAssertEqual(stream2.max(by: <), 3)
    }

    func testSyncStreamDropFirst() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }.dropFirst()
        XCTAssertEqual(stream.prefix(2), [2, 3])
    }

    func testSyncStreamDropWhile() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }.drop(while: { $0 < 2 })
        XCTAssertEqual(stream.prefix(2), [2, 3])
    }

    func testSyncStreamFilter() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }.filter { $0 % 2 != 0 }
        XCTAssertEqual(stream.prefix(2), [1, 3])
    }

    func testSyncStreamMap() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }.map { $0 * 2 }
        XCTAssertEqual(stream.prefix(2), [2, 4])
    }

    func testSyncStreamthrowingMap() throws {
        enum TestError: Error {
            case test
        }

        let stream = try SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(3)
            continuation.finish()
        }.map { value -> Int in
            if value == 2 {
                throw TestError.test
            }
            return value
        }

        XCTAssertEqual(stream, [1, 3])

        XCTAssertThrowsError(try SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }.map { value -> Int in
            if value == 2 {
                throw TestError.test
            }
            return value
        })
    }

    func testSyncStreamCompactMap() {
        let stream = SyncStream<Int?> { continuation in
            continuation.yield(1)
            continuation.yield(nil)
            continuation.yield(3)
            continuation.finish()
        }.compactMap { $0 }
        XCTAssertEqual(stream.prefix(2), [1, 3])
    }

    func testSyncStreamFlatMap() {
        let stream = SyncStream<[Int]> { continuation in
            continuation.yield([1, 2])
            continuation.yield([3, 4])
            continuation.finish()
        }.flatMap { $0 }
        XCTAssertEqual(stream.prefix(4), [1, 2, 3, 4])
    }

    func testSyncStreamReduce() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        let sum = stream.reduce(0, +)
        XCTAssertEqual(sum, 6)
    }

    func testSyncStreamReduceInto() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        let sum = stream.reduce(into: 0) { $0 += $1 }
        XCTAssertEqual(sum, 6)
    }

    func testSyncStreamFrefix() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        XCTAssertEqual(stream.prefix(2), [1, 2])
    }

    func testSyncStreamFrefixWithClousure() {
        let stream = SyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        XCTAssertEqual(stream.prefix(while: { $0 < 3 }), [1, 2])
    }
}
