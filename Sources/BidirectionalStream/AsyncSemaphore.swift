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

import Dispatch
import Foundation

/// An object that is similar to the `DispatchSemaphore` form the `Dispatch` package,
/// but it is designed to be used in an asynchronous context.
public actor AsyncSemaphore {
    // MARK: Lifecycle

    deinit {}

    /// Initializes a new instance of the semaphore with the specified initial value.
    ///
    /// - Parameter value: The initial value of the semaphore.
    public init(value: Int) {
        self.value = value
    }

    // MARK: Public

    /// Signals(increments) the semaphore, allowing one waiting task to resume execution.
    public func signal() async {
        value += 1
        if let work = worksAndIDs.first {
            worksAndIDs.removeFirst()
            queue.sync(execute: work.work)
        }
    }

    /// Waits(decrements) the semaphore, blocking the current task if necessary.
    public func wait() async {
        value -= 1
        if value < 0 {
            await withCheckedContinuation { continuation in
                let workItem = DispatchWorkItem { continuation.resume() }
                worksAndIDs.append((workItem, UUID()))
            }
        }
    }

    /// Waits(decrements) the semaphore with a timeout, blocking the current task if necessary.
    ///
    /// - Parameter timeout: The timeout value.
    /// - Returns: A `DispatchTimeoutResult` indicating whether the wait operation timed out or not.
    public func wait(timeout: DispatchTime) async -> DispatchTimeoutResult {
        await withCheckedContinuation { continuation in
            value -= 1
            if value >= 0 {
                continuation.resume(returning: .success)
                return
            }

            let id = UUID()
            let workItem = DispatchWorkItem { continuation.resume(returning: .success) }
            worksAndIDs.append((workItem, id))

            queue.asyncAfter(deadline: timeout) {
                Task {
                    if await self.remove(work: id) {
                        continuation.resume(returning: .timedOut)
                    }
                }
            }
        }
    }

    /// Waits(decrements) the semaphore with a wall timeout, blocking the current task if necessary.
    ///
    /// - Parameter wallTimeout: The wall timeout value.
    /// - Returns: A `DispatchTimeoutResult` indicating whether the wait operation timed out or not.
    public func wait(wallTimeout: DispatchWallTime) async -> DispatchTimeoutResult {
        await withCheckedContinuation { continuation in
            value -= 1
            if value >= 0 {
                continuation.resume(returning: .success)
                return
            }

            let id = UUID()
            let workItem = DispatchWorkItem { continuation.resume(returning: .success) }
            worksAndIDs.append((workItem, id))

            queue.asyncAfter(wallDeadline: wallTimeout) {
                Task {
                    if await self.remove(work: id) {
                        continuation.resume(returning: .timedOut)
                    }
                }
            }
        }
    }

    // MARK: Private

    private var value: Int
    private let queue = DispatchQueue(label: "coom.BidirectionalStream.AsyncSemaphore.\(UUID().uuidString)")
    private var worksAndIDs: [(work: DispatchWorkItem, id: UUID)] = []

    private func remove(work id: UUID) async -> Bool {
        if let index = worksAndIDs.firstIndex(where: { $0.id == id }) {
            worksAndIDs.remove(at: index)
            value += 1
            return true
        }
        return false
    }
}
