# ``StreamUtilities``

`StreamUtilities` is a toolbox providing two utilities for working with stream in swift:

## Overview

+ `SyncStream`: a class that generates a sequence of values, inspired by `AsyncStream` from the swift standard library, but operates synchronously.
+ `BidirectionalStream`: aims to bring features similar to Python's Generator to Swift. Users can generate values using `yield`, send values back with `send`, and close the stream by throwing a `StopIteration` error.

## Documentation

+ [SyncStream](./SyncStream)
+ [BidirectionalStream](./BidirectionalStream)

## Getting Started

### SyncStream

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

### BidirectionalStream

Inspired by Python generators, which not only can use `yield` to produce values, but also can use `send` to receive values, and `return` to raise a `StopIteration` error and halt the stream, the `BidirectionalSyncStream` and `BidirectionalAsyncStream`  in Swift offer similar features for synchronous and asynchronous operations respectively.

For more information about the generator in python, See: [PEP 255](https://peps.python.org/pep-0255/), [PEP 342](https://peps.python.org/pep-0342/#new-generator-method-send-value), [Doc](https://docs.python.org/3/reference/expressions.html#generator-iterator-methods)

In the following example, the stream uses the `send(_:)` method to send a value back to the stream, which is received by the `yield(_:)` return value.

```swift
let stream = BidirectionalSyncStream<Int, Int, NoneType> { continuation in
    var value = 0
    while true {
        value = continuation.yield(value)
        value += 1
    }
}

try stream.next() // 0 start the stream
try stream.send(5) // 6 send value back to the stream, and get the next value
```

In the following example, when the stream's closure uses `return(_:)` to stop the streaming process, a `StopIteration` error containing the return value will be caught outside the closure.

```swift
let stream = BidirectionalSyncStream<Int, Int, String> { continuation in
    var value = 0
    while true {
        value = continuation.yield(value)
        value += 1
        if value == 5 {
            continuation.return("Stop")
        }
    }
}

try stream.next() // 0 start the stream
do {
    try stream.send(4) // Throw StopIteration error
} catch {
    // get return value
    print((error as! StopIteration).value) // "Stop"
}
```

## Contribution

We welcome contributions to StreamUtilities by opening a pull request on GitHub.

## License

StreamUtilities is released under the Apache License, Version 2.0.

Copyright 2024 Ruiyang Sun
