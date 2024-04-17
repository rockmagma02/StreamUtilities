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
}
