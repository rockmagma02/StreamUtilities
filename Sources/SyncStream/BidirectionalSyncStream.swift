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

// MARK: - StopIteration

/// A special error to indicate the end of the stream.
public struct StopIteration<ReturnT>: Error {
    public var value: ReturnT
}

// MARK: - WrongStreamUse

/// An error to indicate an invalid interaction with the stream.
public struct WrongStreamUse: Error {
    public var message: String
}

// MARK: - NoneType

/// A type to represent `None` in Python.
public struct NoneType {}

// MARK: - BidirectionalSyncStream

/// A mechanism inspired by Python's generator to allow for bidirectional communication between two
/// parties. One party can yield a value and the other party can send a value back.
public class BidirectionalSyncStream<YieldT, SendT, ReturnT> {
    // MARK: Lifecycle

    /// Creates a new `BidirectionalSyncStream`.
    ///
    /// - Parameters:
    ///     - YieldT: The type of the value to yield.
    ///     - SendT: The type of the value to send.
    ///     - ReturnT: The type of the value to return.
    ///     - build: A closure that takes a `Continuation` and returns `Void`.
    public init(
        _: YieldT.Type = YieldT.self,
        _: SendT.Type = SendT.self,
        _: ReturnT.Type = ReturnT.self,
        _ build: @escaping (Continuation) -> Void
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
    public func next() throws -> YieldT {
        if case let .finished(value) = finished {
            throw StopIteration<ReturnT>(value: value)
        }
        if started {
            throw WrongStreamUse(
                message: "The BidirectionalSyncStream has already started, " +
                    "Use send() instead of next() to continue the stream."
            )
        }
        start()

        continuation.yieldSemaphore.wait()
        switch continuation.state {
        case let .yielded(value):
            continuation.state = .waitingForSend
            return value

        case let .finished(value):
            finished = .finished(value)
            throw StopIteration(value: value)

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
    public func send(_ element: SendT) throws -> YieldT {
        guard started else {
            throw WrongStreamUse(
                message: "The BidirectionalSyncStream has not started yet, " +
                    "Use next() to start the stream."
            )
        }

        if case let .finished(value) = finished {
            throw StopIteration<ReturnT>(value: value)
        }

        continuation.sendValue = element
        continuation.state = .sended(element)
        continuation.sendSemaphore.signal()
        continuation.yieldSemaphore.wait()
        switch continuation.state {
        case let .yielded(value):
            continuation.state = .waitingForSend
            return value

        case let .finished(value):
            finished = .finished(value)
            throw StopIteration(value: value)

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
    }

    // MARK: Private

    private var started = false
    private var finished: State = .idle
    private var build: (Continuation) -> Void
    private var continuation: Continuation
    private var queue = DispatchQueue(label: "com.BidirectionalSyncStream.\(UUID().uuidString)")

    private func start() {
        started = true
        queue.async {
            self.build(self.continuation)
        }
    }
}

// MARK: BidirectionalSyncStream.Continuation

public extension BidirectionalSyncStream {
    /// A continuation of the `BidirectionalSyncStream`.
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
        public func yield(_ element: YieldT) -> SendT {
            if finished {
                fatalError("The stream has finished. Cannot yield any more.")
            }

            state = .yielded(element)
            yieldSemaphore.signal()
            sendSemaphore.wait()
            return sendValue!
        }

        /// Returns a value to the stream and finishes the stream.
        /// This is the last call in the stream.
        public func `return`(_ element: ReturnT) {
            if finished {
                fatalError("The stream has finished. Cannot return any more.")
            }

            finished = true
            state = .finished(element)
            yieldSemaphore.signal()
        }

        // MARK: Internal

        internal var state: State = .idle
        internal var yieldSemaphore = DispatchSemaphore(value: 0)
        internal var sendSemaphore = DispatchSemaphore(value: 0)
        internal var sendValue: SendT?

        // MARK: Private

        private var finished = false
    }
}

public extension BidirectionalSyncStream {
    /// Converts the stream to a `SyncStream`.
    ///
    /// Only works when the `SendT` type is `NoneType`, and the `YieldT` type is the same as the `ReturnT` type.
    func toSyncStream() -> SyncStream<YieldT> where SendT.Type == NoneType.Type, YieldT.Type == ReturnT.Type {
        SyncStream<YieldT> { continuation in
            do {
                let value = try self.next()
                continuation.yield(value)
                while true {
                    let value = try self.send(NoneType())
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

    static func makeStream(
        _: YieldT.Type = YieldT.self,
        _: SendT.Type = SendT.self,
        _: ReturnT.Type = ReturnT.self
    ) -> (stream: BidirectionalSyncStream<YieldT, SendT, ReturnT>, continuation: BidirectionalSyncStream<YieldT, SendT, ReturnT>.Continuation) {
        let stream = BidirectionalSyncStream { _ in }
        let continuation = stream.continuation
        return (stream, continuation)
    }
}
