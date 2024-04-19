# ``SyncStream/SyncStream``

## Overview

[SyncStream](syncstream/syncstream) is inspired by Swift's [`AsyncStream`](https://developer.apple.com/documentation/swift/asyncstream) and offers a convenient way to generate a sequence using a closure, without the need to implement the `Sequence` protocol.

Just like the [`AsyncStream`](https://developer.apple.com/documentation/swift/asyncstream) , the [SyncStream](syncstream/syncstream) also utilizes a class called [Continuation](syncstream/syncstream/continuation) to manage the production progress. The [Continuation](syncstream/syncstream/continuation) offers two main methods, [`yield(_:)`](syncstream/syncstream/continuation/yield(_:)) and [`finish`](syncstream/syncstream/continuation/finish()), similar to those in the [`AsyncStream`](https://developer.apple.com/documentation/swift/asyncstream), but operates synchronously. If you are familiar with Python, you can consider the  [SyncStream](syncstream/syncstream) as a generator.

```swift
let stream = SyncStream<Int> { continuation in
    for i in 0..<10 {
        continuation.yield(i)
    }
    continuation.finish()
}

for value in stream {
print(value, terminator: " ")
}
// 0 1 2 3 4 5 6 7 8 9
```

## Topics

### Creating a Continuation-Based Stream

- ``init(_:_:)``
- ``init(unfolding:)``
- ``Continuation``

### Finding Elements

- ``contains(_:)``
- ``contains(where:)``
- ``allSatisfy(_:)``
- ``first(where:)``
- ``min()``
- ``min(by:)``
- ``max()``
- ``max(by:)``

### Selecting Elements

- ``prefix(_:)``
- ``prefix(while:)``

### Extracting Elements

- ``dropFirst(_:)``
- ``drop(while:)``
- ``filter(_:)``

### Transforming a Sequence

- ``map(_:)-hk46``
- ``map(_:)-5vrbe``
- ``compactMap(_:)``
- ``flatMap(_:)``
- ``reduce(_:_:)``
- ``reduce(into:_:)``
