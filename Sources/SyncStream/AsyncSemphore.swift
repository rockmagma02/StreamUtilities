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

@available(macOS 10.15, *)
internal actor AsyncSemphore {
    // MARK: Lifecycle

    deinit {}

    internal init(value: Int) {
        self.value = value
    }

    // MARK: Internal

    internal func wait() async {
        value -= 1
        if value < 0 {
            _ = await withCheckedContinuation { continuation in
                let workItem = DispatchWorkItem { continuation.resume() }
                self.worksAndIDs.append((workItem, UUID()))
            }
        }
    }

    internal func wait(timeout: DispatchTime) async -> DispatchTimeoutResult {
        await withCheckedContinuation { continuation in
            value -= 1
            if value >= 0 {
                continuation.resume(returning: .success)
                return
            }

            let id = UUID()
            let workItem = DispatchWorkItem { continuation.resume(returning: .success) }
            self.worksAndIDs.append((workItem, id))

            queue.asyncAfter(deadline: timeout) {
                Task {
                    if await self.removeWork(withID: id) {
                        continuation.resume(returning: .timedOut)
                    }
                }
            }
        }
    }

    internal func wait(wallTimeout: DispatchWallTime) async -> DispatchTimeoutResult {
        await withCheckedContinuation { continuation in
            value -= 1
            if value >= 0 {
                continuation.resume(returning: .success)
                return
            }

            let id = UUID()
            let workItem = DispatchWorkItem { continuation.resume(returning: .success) }
            self.worksAndIDs.append((workItem, id))

            queue.asyncAfter(wallDeadline: wallTimeout) {
                Task {
                    if await self.removeWork(withID: id) {
                        continuation.resume(returning: .timedOut)
                    }
                }
            }
        }
    }

    internal func signal() async {
        value += 1
        if let work = worksAndIDs.first {
            worksAndIDs.removeFirst()
            queue.sync(execute: work.work)
        }
    }

    // MARK: Private

    private var value: Int
    private var queue = DispatchQueue(label: "com.AsyncDispatchSemphore.\(UUID().uuidString)")
    private var worksAndIDs = [(work: DispatchWorkItem, id: UUID)]()

    private func removeWork(withID id: UUID) async -> Bool {
        if let index = worksAndIDs.firstIndex(where: { $0.id == id }) {
            worksAndIDs.remove(at: index)
            value += 1
            return true
        }
        return false
    }
}
