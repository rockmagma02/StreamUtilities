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

final class BidirectionalSyncStreamTests: XCTestCase {
    func testBidirectionalSyncStreamYieldAndSend() throws {
        let expectation = expectation(description: "BidirectionalSyncStream yields and sends values correctly")
        var receivedYields = [Int]()
        let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
            let first = continuation.yield(1)
            XCTAssertEqual(first, 2)
            let second = continuation.yield(3)
            XCTAssertEqual(second, 4)
            continuation.return(NoneType())
        }

        DispatchQueue.global().async {
            do {
                let firstYield = try stream.next()
                receivedYields.append(firstYield)
                let secondYield = try stream.send(2)
                receivedYields.append(secondYield)
                _ = try stream.send(4)
            } catch {
                XCTAssertNotNil(error as? StopIteration<NoneType>)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
        XCTAssertEqual(receivedYields, [1, 3])
    }

    func testBidirectionalSyncStreamStopIteration() {
        let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
            continuation.return(NoneType())
        }

        XCTAssertThrowsError(try stream.next()) { error in
            XCTAssertNotNil(error as? StopIteration<NoneType>)
            XCTAssertNotNil((error as? StopIteration<NoneType>)?.value)
        }
    }

    func testBidirectionalSyncStreamWrongUse() {
        let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
            continuation.yield(1)
        }

        XCTAssertThrowsError(try stream.send(1)) { error in
            XCTAssertTrue(error is WrongStreamUse)
        }
    }

    func testNextafterStarted() {
        let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
            continuation.yield(1)
        }

        _ = try? stream.next()
        XCTAssertThrowsError(try stream.next()) { error in
            XCTAssertTrue(error is WrongStreamUse)
        }
    }

    func testCalledAfterFinished() {
        let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
            continuation.return(NoneType())
        }

        _ = try? stream.next()
        XCTAssertThrowsError(try stream.next()) { error in
            XCTAssertTrue(error is StopIteration<NoneType>)
        }
        XCTAssertThrowsError(try stream.next()) { error in
            XCTAssertTrue(error is StopIteration<NoneType>)
        }
        XCTAssertThrowsError(try stream.send(1)) { error in
            XCTAssertTrue(error is StopIteration<NoneType>)
        }
    }

    func testToSyncStream() {
        let bidStream = BidirectionalSyncStream<Int, NoneType, Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.return(3)
        }
        let stream = bidStream.toSyncStream()
        for idx in 1 ... 3 {
            XCTAssertEqual(stream.next(), idx)
        }
        XCTAssertNil(stream.next())
    }
}
