# ``SyncStream/SyncStream``

## Overview

[`AsyncStream`](https://developer.apple.com/documentation/swift/asyncstream) offers a convenient method to create a sequence from a closure that invokes a continuation to generate elements. However, in certain cases, you may need to produce a sequence synchronously using a closure. To address this need, we introduce [`SyncStream`](syncstream/syncstream), which shares the same API as `AsyncStream` but operates synchronously.

In detail, the most common way to initialize a `SyncStream` is providing a closure that takes a `Continuation` argument. The `Continuation` class provides two key methods, `yield(_:)` and `finish()`, to manage the element production procedure.

Because of the synchronous feature, the closure will not execute until you start iterating over the stream.

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
- ``filter(_:)-6h5ix``
- ``filter(_:)-7wb05``

### Transforming a Sequence

- ``map(_:)``
- ``compactMap(_:)``
- ``flatMap(_:)-uifn``
- ``flatMap(_:)-5btn7``
- ``reduce(_:_:)``
- ``reduce(into:_:)``
