# ``SyncStream``

`SyncStream` is a class that generates a sequence of values, inspired by `AsyncStream` from the swift standard library.

## Overview

[`AsyncStream`](https://developer.apple.com/documentation/swift/asyncstream) offers a convenient method to create a sequence from a closure that invokes a continuation to generate elements. However, in certain cases, you may need to produce a sequence synchronously using a closure. To address this need, we introduce [`SyncStream`](syncstream/syncstream), which shares the same API as `AsyncStream` but operates synchronously.

Here is a simple example of how to use `SyncStream`:

```swift
let stream = SyncStream<Int> { continuation in
    for i in 0 ..< 10 {
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

+ ``SyncStream-class``
+ ``SyncStream/Continuation``
