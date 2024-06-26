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
public class SyncStream<Element>: Sequence, IteratorProtocol {
    // MARK: Lifecycle

    /// Constructs an synchronous stream for an element type, using am element-producing closure.
    ///
    /// Parameters:
    ///    - build: A closure that takes a continuation and uses it to produce elements.
    ///
    /// ## Example
    /// ```swift
    /// let stream = SyncStream<Int> { continuation in
    ///      continuation.yield(1)
    ///      continuation.yield(2)
    ///      continuation.finish()
    ///      continuation.yield(3) // This will be ignored
    /// }
    ///
    /// for element in stream {
    ///     print(element, terminator: " ")
    /// }
    /// // 1 2
    /// ```
    public init(_: Element.Type = Element.self, _ build: @escaping (SyncStream<Element>.Continuation) -> Void) {
        let getValueSemaphore = DispatchSemaphore(value: 0)
        let runFunctionSemaphore = DispatchSemaphore(value: 0)
        let continuation = SyncStream<Element>.Continuation(
            getValueSemaphore: getValueSemaphore,
            runFunctionSemaphore: runFunctionSemaphore
        )

        self.getValueSemaphore = getValueSemaphore
        self.runFunctionSemaphore = runFunctionSemaphore
        self.continuation = continuation

        let queue = DispatchQueue(label: "com.SyncStream.\(UUID().uuidString)")
        queue.async {
            runFunctionSemaphore.wait()
            build(continuation)
        }
    }

    /// Constructs an synchronous stream from a given element-producing closure.
    ///
    /// Parameters:
    ///   - produce: A closure that produces elements, returning `nil` when the stream is finished.
    ///
    /// ## Example
    /// ```swift
    /// let stream = SyncStream<Int> {
    ///     let value = Int.random(in: 1...10)
    ///     if value == 5 { return nil }
    /// }
    /// ```
    public convenience init(unfolding produce: @escaping () -> Element?) {
        self.init(Element.self) { continuation in
            while let element = produce() {
                continuation.yield(element)
            }
            continuation.finish()
        }
    }

    deinit {}

    // MARK: Public

    /// Constructs an synchronous stream from the Element Type
    /// - Parameter of: The Element Type
    ///
    /// - Returns: A tuple containing the stream and its continuation. The continuation
    ///     should be passed to the producer while the stream should be passed to the consumer.
    public static func makeStream(
        of _: Element.Type = Element.self
    ) -> (stream: SyncStream<Element>, continuation: SyncStream<Element>.Continuation) {
        let stream = SyncStream<Element> { _ in }
        let continuation = stream.continuation
        return (stream, continuation)
    }

    public func next() -> Element? {
        if finished {
            return nil
        }

        runFunctionSemaphore.signal()
        getValueSemaphore.wait()
        switch continuation.value {
        case let .element(element):
            return element

        case .finish:
            finished = true
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
    private var finished = false
}
