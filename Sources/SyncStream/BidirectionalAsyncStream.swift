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

// MARK: - BidirectionalAsyncStream

/// A mechanism inspired by Python's generator to allow for bidirectional communication between two
/// parties. One party can yield a value and the other party can send a value back.
@available(macOS 10.15, *)
public class BidirectionalAsyncStream<YieldT, SendT, ReturnT> {
    // MARK: Lifecycle

    /// Creates a new `BidirectionalSyncStream`.
    ///
    /// - Parameters:
    ///     - YieldT: The type of the value to yield.
    ///     - SendT: The type of the value to send.
    ///     - ReturnT: The type of the value to return.
    ///     - build: A async closure that takes a `Continuation` and returns `Void`.
    public init(
        _: YieldT.Type = YieldT.self,
        _: SendT.Type = SendT.self,
        _: ReturnT.Type = ReturnT.self,
        _ build: @escaping (Continuation) async -> Void
    ) {
        self.build = build
        continuation = Continuation()
    }

    deinit {}

    // MARK: Public

    /// Advances the stream to the next value. In this stream, it is used to
    /// start the stream.
    ///
    /// - Returns: The next value in the stream.
    /// - Throws: `StopIteration` if the stream has finished.
    /// - Throws: `WrongStreamUse` if invalid interaction with the stream is detected.
    public func next() async throws -> YieldT {
        if case let .finished(value) = finished {
            throw StopIteration<ReturnT>(value: value)
        }
        if case let .error(value) = finished {
            throw value
        }
        if started {
            throw WrongStreamUse(
                message: "The BidirectionalSyncStream has already started, " +
                    "Use send() instead of next() to continue the stream."
            )
        }
        await start()

        await continuation.yieldSemaphore.wait()
        switch continuation.state {
        case let .yielded(value):
            continuation.state = .waitingForSend
            return value

        case let .finished(value):
            finished = .finished(value)
            throw StopIteration(value: value)

        case let .error(value):
            finished = .error(value)
            throw value

        default:
            throw WrongStreamUse(message: "yield or return must be called in the continuation closure")
        }
    }

    /// Sends a value to the stream, and returns the next value.
    ///
    /// - Parameters:
    ///     - element: The value to send.
    ///
    /// - Returns: The next value in the stream.
    ///
    /// - Throws: `StopIteration` if the stream has finished.
    /// - Throws: `WrongStreamUse` if invalid interaction with the stream is detected.
    ///
    /// - Note: This method can only be called after calling `next()`.
    public func send(_ element: SendT) async throws -> YieldT {
        guard started else {
            throw WrongStreamUse(
                message: "The BidirectionalSyncStream has not started yet, " +
                    "Use next() to start the stream."
            )
        }

        if case let .finished(value) = finished {
            throw StopIteration<ReturnT>(value: value)
        }
        if case let .error(value) = finished {
            throw value
        }

        continuation.sendValue = element
        continuation.state = .sended(element)
        await continuation.sendSemaphore.signal()
        await continuation.yieldSemaphore.wait()
        switch continuation.state {
        case let .yielded(value):
            continuation.state = .waitingForSend
            return value

        case let .finished(value):
            finished = .finished(value)
            throw StopIteration(value: value)

        case let .error(value):
            finished = .error(value)
            throw value

        default:
            throw WrongStreamUse(message: "yield or return must be called in the continuation closure")
        }
    }

    // MARK: Internal

    internal enum State {
        case idle
        case yielded(YieldT)
        case waitingForSend
        case sended(SendT)
        case finished(ReturnT)
        case error(Terminated)
    }

    // MARK: Private

    private var started = false
    private var finished: State = .idle
    private var build: (Continuation) async -> Void
    private var continuation: Continuation
    private var queue = DispatchQueue(label: "com.BidirectionalAsyncStream.\(UUID().uuidString)")

    private func start() async {
        started = true
        Task { await build(continuation) }
    }
}

// MARK: BidirectionalAsyncStream.Continuation

@available(macOS 10.15, *)
public extension BidirectionalAsyncStream {
    /// A continuation of the `BidirectionalAsyncStream`.
    /// It is used to communicate between the two parties.
    class Continuation {
        // MARK: Lifecycle

        deinit {}

        // MARK: Public

        /// Yields a value to the stream and waits for a value to be sent back.
        ///
        /// - Parameters:
        ///     - element: The value to yield.
        ///
        /// - Returns: The value sent back.
        @discardableResult
        public func yield(_ element: YieldT) async -> SendT {
            if finished {
                fatalError("The stream has finished. Cannot yield any more.")
            }

            state = .yielded(element)
            await yieldSemaphore.signal()
            await sendSemaphore.wait()
            return sendValue!
        }

        /// Returns a value to the stream and finishes the stream.
        /// This is the last call in the stream.
        public func `return`(_ element: ReturnT) async {
            if finished {
                fatalError("The stream has finished. Cannot return any more.")
            }

            finished = true
            state = .finished(element)
            await yieldSemaphore.signal()
        }

        /// Throws an error to the stream and finishes the stream.
        /// This is the last call in the stream.
        ///
        /// - Parameters:
        ///     - error: The error to throw.
        public func `throw`(
            error: any Error,
            fileName: String = #file,
            functionName: String = #function,
            lineNumber: Int = #line,
            columnNumber: Int = #column
        ) async {
            if finished {
                fatalError("The stream has finished. Cannot return any more.")
            }

            finished = true

            let filename = (fileName as NSString).lastPathComponent
            let terminated = Terminated(
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber,
                columnNumber: columnNumber,
                error: error
            )
            state = .error(terminated)
            await yieldSemaphore.signal()
        }

        // MARK: Internal

        internal var state: State = .idle
        internal var yieldSemaphore = AsyncSemphore(value: 0)
        internal var sendSemaphore = AsyncSemphore(value: 0)
        internal var sendValue: SendT?

        // MARK: Private

        private var finished = false
    }
}

@available(macOS 10.15, *)
public extension BidirectionalAsyncStream {
    /// Converts the stream to a `SyncStream`.
    ///
    /// Only works when the `SendT` type is `NoneType`, and the `YieldT` type is the same as the `ReturnT` type.
    func toAsyncStream() async -> AsyncStream<YieldT> where SendT.Type == NoneType.Type, YieldT.Type == ReturnT.Type {
        AsyncStream<YieldT> { continuation in
            Task {
                do {
                    let value = try await self.next()
                    continuation.yield(value)
                    while true {
                        let value = try await self.send(NoneType())
                        continuation.yield(value)
                    }
                } catch {
                    if let value = (error as? StopIteration<ReturnT>)?.value {
                        continuation.yield(value)
                    }
                    continuation.finish()
                }
            }
        }
    }

    /// Constructs an Bidrectional asynchronous stream from the Element Type
    ///
    /// - Returns: A tuple containing the stream and its continuation. The continuation
    ///     should be passed to the producer while the stream should be passed to the consumer.
    static func makeStream(
        _: YieldT.Type = YieldT.self,
        _: SendT.Type = SendT.self,
        _: ReturnT.Type = ReturnT.self
    ) -> (
        stream: BidirectionalAsyncStream<YieldT, SendT, ReturnT>,
        continuation: BidirectionalAsyncStream<YieldT, SendT, ReturnT>.Continuation
    ) {
        let stream = BidirectionalAsyncStream<YieldT, SendT, ReturnT> { _ in }
        let continuation = stream.continuation
        return (stream, continuation)
    }
}
