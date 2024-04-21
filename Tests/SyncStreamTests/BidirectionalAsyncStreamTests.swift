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

final class BidirectionalAsyncStreamTests: XCTestCase {
    func testBidirectionalAsyncStreamYieldAndSend() async throws {
        let expectation = expectation(description: "BidirectionalSyncStream yields and sends values correctly")
        let stream = BidirectionalAsyncStream<Int, Int, NoneType> { continuation in
            let first = await continuation.yield(1)
            XCTAssertEqual(first, 2)
            let second = await continuation.yield(3)
            XCTAssertEqual(second, 4)
            await continuation.return(NoneType())
        }

        do {
            var receivedYields = [Int]()
            let firstYield = try await stream.next()
            receivedYields.append(firstYield)
            let secondYield = try await stream.send(2)
            receivedYields.append(secondYield)
            _ = try await stream.send(4)
            XCTAssertEqual(receivedYields, [1, 3])
        } catch {
            XCTAssertNotNil(error as? StopIteration<NoneType>)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }

    func testBidirectionalSyncStreamStopIteration() async {
        let stream = BidirectionalAsyncStream<Int, Int, NoneType> { continuation in
            await continuation.return(NoneType())
        }

        let expectation = expectation(description: "BidirectionalSyncStream return correctly")
        do {
            _ = try await stream.next()
        } catch {
            XCTAssertNotNil(error as? StopIteration<NoneType>)
            XCTAssertNotNil((error as? StopIteration<NoneType>)?.value)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }

    func testBidirectionalSyncStreamWrongUse() async {
        let stream = BidirectionalAsyncStream<Int, Int, NoneType> { continuation in
            await continuation.yield(1)
        }

        let expectation = expectation(description: "BidirectionalSyncStream throws WrongStreamUse")
        do {
            _ = try await stream.send(1)
        } catch {
            XCTAssertTrue(error is WrongStreamUse)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }

    func testNextafterStarted() async {
        let stream = BidirectionalAsyncStream<Int, Int, NoneType> { continuation in
            await continuation.yield(1)
        }

        _ = try? await stream.next()
        let expectation = expectation(description: "BidirectionalSyncStream throws WrongStreamUse")
        do {
            _ = try await stream.next()
        } catch {
            XCTAssertTrue(error is WrongStreamUse)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }

    func testCalledAfterFinished() async {
        let stream = BidirectionalAsyncStream<Int, Int, NoneType> { continuation in
            await continuation.return(NoneType())
        }

        _ = try? await stream.next()
        let expectation1 = expectation(description: "BidirectionalSyncStream should return")
        do {
            _ = try await stream.next()
        } catch {
            XCTAssertTrue(error is StopIteration<NoneType>)
            expectation1.fulfill()
        }
        let expectation2 = expectation(description: "BidirectionalSyncStream should return")
        do {
            _ = try await stream.next()
        } catch {
            XCTAssertTrue(error is StopIteration<NoneType>)
            expectation2.fulfill()
        }
        let expectation3 = expectation(description: "BidirectionalSyncStream should return")
        do {
            _ = try await stream.send(1)
        } catch {
            XCTAssertTrue(error is StopIteration<NoneType>)
            expectation3.fulfill()
        }

        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 5)
    }

    func testToSyncStream() async {
        let bidStream = BidirectionalAsyncStream<Int, NoneType, Int> { continuation in
            await continuation.yield(1)
            await continuation.yield(2)
            await continuation.return(3)
        }
        let stream = await bidStream.toAsyncStream()
        var idx = 1
        for try await element in stream {
            XCTAssertEqual(element, idx)
            idx += 1
        }
    }
}
