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

public extension SyncStream {
    /// Returns a Boolean value that indicates whether the synchronous sequence contains the given element.
    ///
    /// Parameters:
    ///  - search: The element to find in the synchronous sequence.
    ///
    ///  Returns:
    ///  `true` if the synchronous sequence contains the given element; otherwise, `false`.
    func contains(_ search: Element) -> Bool where Element: Equatable {
        for element in self where element == search {
            return true
        }
        return false
    }

    /// Returns a Boolean value that indicates whether the synchronous sequence contains an
    /// element that satisfies the given predicate.
    ///
    /// Parameters:
    /// - predicate: A closure that takes an element as its argument and returns a Boolean
    ///     value that indicates whether the element satisfies a condition.
    ///
    /// Returns:
    /// `true` if the synchronous sequence contains an element that satisfies the given predicate;
    ///  otherwise, `false`.
    func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        for element in self where try predicate(element) {
            return true
        }
        return false
    }

    /// Returns a Boolean value that indicates whether every element of a synchronous sequence
    /// satisfies a given predicate.
    ///
    /// Parameters:
    /// - predicate: A closure that takes an element as its argument and returns a Boolean
    ///    value that indicates whether the element satisfies a condition.
    ///
    /// Returns:
    /// `true` if the synchronous sequence contains only elements that satisfy the given predicate;
    /// otherwise, `false`.
    func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for element in self where try !predicate(element) {
            return false
        }
        return true
    }

    /// Returns the first element of the sequence that satisfies the given predicate.
    ///
    /// Parameters:
    ///  - where: A closure that takes an element as its argument and returns a Boolean value
    ///   that indicates whether the element is a match.
    ///
    /// Returns:
    ///     The first element of the sequence that satisfies the given predicate. If there is
    ///     no element that satisfies the predicate, the method returns `nil`.
    func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        for element in self where try predicate(element) {
            return element
        }
        return nil
    }

    /// Returns the minimum element in the sequence.
    ///
    /// Returns:
    ///    The minimum element in the sequence. If the sequence has no elements, the method
    ///    returns `nil`.
    func min() -> Element? where Element: Comparable {
        var minElement: Element?
        for element in self {
            if let min = minElement {
                if element < min {
                    minElement = element
                }
            } else {
                minElement = element
            }
        }
        return minElement
    }

    /// Returns the minimum element in the sequence, using the given predicate as the comparison
    /// between elements.
    ///
    /// Parameters:
    ///  - by: A closure that takes two arguments and returns a Boolean value that indicates
    ///     whether the first argument should be ordered before the second argument.
    ///
    /// Returns:
    ///   The minimum element in the sequence. If the sequence has no elements, the method
    ///   returns `nil`.
    func min(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        var minElement: Element?
        for element in self {
            if let min = minElement {
                if try areInIncreasingOrder(element, min) {
                    minElement = element
                }
            } else {
                minElement = element
            }
        }
        return minElement
    }

    /// Returns the maximum element in the sequence.
    ///
    /// Returns:
    ///     The maximum element in the sequence. If the sequence has no elements, the method
    ///     returns `nil`.
    func max() -> Element? where Element: Comparable {
        var maxElement: Element?
        for element in self {
            if let max = maxElement {
                if element > max {
                    maxElement = element
                }
            } else {
                maxElement = element
            }
        }
        return maxElement
    }

    /// Returns the maximum element in the sequence, using the given predicate as the comparison
    /// between elements.
    ///
    /// Parameters:
    ///     - by: A closure that takes two arguments and returns a Boolean value that indicates
    ///     whether the first argument should be ordered before the second argument.
    ///
    /// Returns:
    ///     The maximum element in the sequence. If the sequence has no elements, the method
    ///     returns `nil`.
    func max(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        var maxElement: Element?
        for element in self {
            if let max = maxElement {
                if try areInIncreasingOrder(max, element) {
                    maxElement = element
                }
            } else {
                maxElement = element
            }
        }
        return maxElement
    }

    /// Returns an Array, up to the specified maximum length, containing the initial
    /// elements of the base synchronous sequence.
    ///
    /// Parameters:
    ///     - count: The maximum number of elements to return.
    ///
    /// Returns:
    ///     An Array containing the initial elements of the synchronous sequence, up to
    ///     the specified maximum length.
    func prefix(_ count: Int) -> [Element] {
        var result: [Element] = []
        for element in self {
            if result.count < count {
                result.append(element)
            } else {
                break
            }
        }
        return result
    }

    /// Returns an Array containing the initial elements of the synchronous sequence that
    /// satisfy the given predicate.
    ///
    /// Parameters:
    ///     - predicate: A closure that takes an element as its argument and returns a Boolean
    ///     value that indicates whether the element should be included in the result.
    ///
    /// Returns:
    ///     An Array containing the initial elements of the synchronous sequence that satisfy
    ///     the given predicate.
    func prefix(while predicate: (Element) throws -> Bool) rethrows -> [Element] {
        var result: [Element] = []
        for element in self {
            if try predicate(element) {
                result.append(element)
            } else {
                break
            }
        }
        return result
    }

    /// Returns a SyncStream containing the elements of the base synchronous sequence, with
    /// the specified number of elements skipped from the beginning.
    ///
    /// Parameters:
    ///     - count: The number of elements to skip. default is 1.
    ///
    /// Returns:
    ///     A SyncStream containing the elements of the synchronous sequence, starting at the
    ///     specified number of elements from the beginning.
    func dropFirst(_ count: Int = 1) -> SyncStream<Element> {
        var index = 0
        return SyncStream { continuation in
            for element in self {
                if index >= count {
                    continuation.yield(element)
                }
                index += 1
            }
            continuation.finish()
        }
    }

    /// Returns a SyncStream containing the elements of the base synchronous sequence, with
    /// the initial elements omitted until the predicate returns `false`.
    ///
    /// Parameters:
    ///     - while: A closure that takes an element as its argument and returns a Boolean value
    ///         that indicates whether the element should be omitted from the result.
    ///
    /// Returns:
    ///     A SyncStream containing the elements of the synchronous sequence, starting at the
    ///     first element for which the predicate returns `false`.
    func drop(while predicate: @escaping (Element) -> Bool) -> SyncStream<Element> {
        var isDropped = false
        return SyncStream { continuation in
            for element in self {
                if !isDropped {
                    if !predicate(element) {
                        isDropped = true
                        continuation.yield(element)
                    }
                } else {
                    continuation.yield(element)
                }
            }
            continuation.finish()
        }
    }

    /// Creates an synchronous stream that contains, in order, the elements of the base
    /// sequence that satisfy the given predicate.
    ///
    /// Parameters:
    ///     - isIncluded: A closure that takes an element as its argument and returns a Boolean
    ///         value that indicates whether the element should be included in the returned
    ///
    /// Returns:
    ///     A SyncStream containing the elements of the base synchronous sequence that satisfy
    ///     the given predicate.
    func filter(_ isIncluded: @escaping (Element) -> Bool) -> SyncStream<Element> {
        SyncStream { continuation in
            for element in self where isIncluded(element) {
                continuation.yield(element)
            }
            continuation.finish()
        }
    }

    /// Creates an synchronous stream that maps the given closure over the synchronous sequence’s
    /// elements.
    ///
    /// Parameters:
    ///     - transform: A closure that takes an element of the synchronous sequence as its
    ///         argument and returns a transformed value of the same or of a different type.
    ///
    /// Returns:
    ///     A SyncStream that contains the transformed elements of the base synchronous sequence.
    func map<T>(_ transform: @escaping (Element) -> T) -> SyncStream<T> {
        SyncStream<T> { continuation in
            for element in self {
                continuation.yield(transform(element))
            }
            continuation.finish()
        }
    }

    /// Creates an synchronous stream that maps the given throwing closure over the synchronous
    /// sequence’s elements.
    ///
    /// Parameters:
    ///     - transform: A throwing closure that takes an element of the synchronous sequence as
    ///         its argument and returns a transformed value of the same or of a different type.
    ///
    /// Returns:
    ///     A SyncStream that contains the transformed elements of the base synchronous sequence.
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for element in self {
            try result.append(transform(element))
        }
        return result
    }

    /// Returns a SyncStream containing the non-`nil` results of calling the given
    /// transformation with each element of this sequence.
    ///
    /// Parameters:
    ///     - transform: A closure that accepts an element of this sequence as its argument and
    ///         returns an optional value.
    ///
    /// Returns:
    ///     A SyncStream of the non-`nil` results of calling `transform` with each element of
    ///     the sequence.
    func compactMap<T>(_ transform: @escaping (Element) -> T?) -> SyncStream<T> {
        SyncStream<T> { continuation in
            for element in self {
                if let transformed = transform(element) {
                    continuation.yield(transformed)
                }
            }
            continuation.finish()
        }
    }

    /// Returns a SyncStream that concatenates the results of calling the given transformation
    /// with each element of this sequence.
    ///
    /// Parameters:
    ///     - transform: A closure that accepts an element of this sequence as its argument and
    ///         returns a sequence or collection.
    ///
    /// Returns:
    ///     A SyncStream that concatenates the results of calling `transform` with each element
    ///     of the sequence.
    func flatMap<T>(_ transform: @escaping (Element) -> any Sequence<T>) -> SyncStream<T> {
        SyncStream<T> { continuation in
            for element in self {
                for transformed in transform(element) {
                    continuation.yield(transformed)
                }
            }
            continuation.finish()
        }
    }

    /// Returns the result of combining the elements of the synchronous sequence using the given closure.
    ///
    /// Parameters:
    ///     - initialResult: The value to use as the initial accumulating value.
    ///     - nextPartialResult: A closure that combines an accumulating value and an element of the
    ///         sequence into a new accumulating value.
    ///
    /// Returns:
    ///     The final accumulated value. If the sequence has no elements, the result is `initialResult`.
    func reduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Element) throws -> T) rethrows -> T {
        var result = initialResult
        for element in self {
            result = try nextPartialResult(result, element)
        }
        return result
    }

    /// Returns the result of combining the elements of the synchronous sequence using the given
    /// closure, given a mutable initial value.
    ///
    /// Parameters:
    ///     - into: The value to use as the initial accumulating value.
    ///     - updateAccumulatingResult: A closure that updates the accumulating value with an
    ///         element of the sequence.
    ///
    /// Returns:
    ///     The final accumulated value. If the sequence has no elements, the result is `into`.
    func reduce<T>(into: T, _ updateAccumulatingResult: @escaping (inout T, Element) throws -> Void) rethrows -> T {
        var result = into
        for element in self {
            try updateAccumulatingResult(&result, element)
        }
        return result
    }
}
