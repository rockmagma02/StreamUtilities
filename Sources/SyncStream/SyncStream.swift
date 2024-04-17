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

/// An synchronous sequence generated from a closure that calls a continuation to produce new elements.
public struct SyncStream<Element>: Sequence, IteratorProtocol {
    // MARK: Lifecycle

    /// Constructs an synchronous stream for an element type, using am element-producing closure.
    ///
    /// Parameters:
    ///    - build: A closure that takes a continuation and uses it to produce elements.
    public init(_: Element.Type = Element.self, _ build: @escaping (SyncStream<Element>.Continuation) -> Void) {
        let getValueSemaphore = DispatchSemaphore(value: 0)
        let runFuncitonSemaphore = DispatchSemaphore(value: 0)
        let continuation = SyncStream<Element>.Continuation(
            getValueSemaphore: getValueSemaphore,
            runFuncitonSemaphore: runFuncitonSemaphore
        )

        self.getValueSemaphore = getValueSemaphore
        runFunctionSemaphore = runFuncitonSemaphore
        self.continuation = continuation

        let queue = DispatchQueue(label: "com.SyncStream.\(UUID().uuidString)")
        queue.async {
            runFuncitonSemaphore.wait()
            build(continuation)
        }
    }

    /// Constructs an synchronous stream from a given element-producing closure.
    ///
    /// Parameters:
    ///   - produce: A closure that produces elements, returning `nil` when the stream is finished.
    public init(unfolding produce: @escaping () -> Element?) {
        self.init(Element.self) { continuation in
            while let element = produce() {
                continuation.yield(element)
            }
            continuation.finish()
        }
    }

    // MARK: Public

    public func next() -> Element? {
        runFunctionSemaphore.signal()
        getValueSemaphore.wait()
        switch continuation.value {
        case let .element(element):
            return element

        case .finish:
            return nil
        }
    }

    public func makeIterator() -> SyncStream<Element> {
        self
    }

    // MARK: Private

    private let getValueSemaphore: DispatchSemaphore
    private let runFunctionSemaphore: DispatchSemaphore
    private let continuation: SyncStream<Element>.Continuation
}
