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

@available(macOS 10.15, *)
final class AsyncDispatchSemaphoreTests: XCTestCase {
    func testSemaphoreInitialization() async {
        let semaphore = AsyncSemphore(value: 1)
        await semaphore.signal() // Increase the semaphore to ensure it's initialized correctly.
        await semaphore.wait() // This should pass immediately if the semaphore was initialized with value 1.
    }

    func testSemaphoreWaitAndSignal() async {
        let semaphore = AsyncSemphore(value: 0)

        let expectation = XCTestExpectation(description: "Semaphore signal")

        Task {
            await semaphore.wait()
            expectation.fulfill()
        }

        await semaphore.signal() // This should fulfill the expectation by allowing the wait to complete.

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testSemaphoreWaitWithTimeoutSuccess() async {
        let semaphore = AsyncSemphore(value: 1)

        let start = Date()
        let result = await semaphore.wait(timeout: .now() + 0.5)
        XCTAssertEqual(result, .success)
        let end = Date()
        XCTAssertTrue(end.timeIntervalSince(start) <= 0.5)
    }

    func testSemaphoreWaitWithTimeoutBySignal() async {
        let semaphore = AsyncSemphore(value: 0)

        let expectation = XCTestExpectation(description: "Semaphore signal")

        Task {
            let result = await semaphore.wait(timeout: .now() + 3.0)
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }

        await semaphore.signal() // This should fulfill the expectation by allowing the wait to complete.

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testSemaphoreWaitWithTimeoutFailure() async {
        let semaphore = AsyncSemphore(value: 0)

        let start = Date()
        let result = await semaphore.wait(timeout: .now() + 0.5)
        XCTAssertEqual(result, .timedOut)
        let end = Date()
        XCTAssertTrue(end.timeIntervalSince(start) >= 0.5)
    }

    func testSemphoreWaitWithWallTimeoutBySignal() async {
        let semaphore = AsyncSemphore(value: 0)

        let expectation = XCTestExpectation(description: "Semaphore signal")

        Task {
            let result = await semaphore.wait(wallTimeout: .now() + 3.0)
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }

        await semaphore.signal() // This should fulfill the expectation by allowing the wait to complete.

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testSemaphoreWaitWithWallTimeoutSuccess() async {
        let semaphore = AsyncSemphore(value: 1)

        let start = Date()
        let result = await semaphore.wait(wallTimeout: .now() + 0.5)
        XCTAssertEqual(result, .success)
        let end = Date()
        XCTAssertTrue(end.timeIntervalSince(start) <= 0.5)
    }

    func testSemaphoreWaitWithWallTimeoutFailure() async {
        let semaphore = AsyncSemphore(value: 0)

        let start = Date()
        let result = await semaphore.wait(wallTimeout: .now() + 0.5)
        XCTAssertEqual(result, .timedOut)
        let end = Date()
        XCTAssertTrue(end.timeIntervalSince(start) >= 0.5)
    }
}
