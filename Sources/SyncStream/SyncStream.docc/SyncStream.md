# ``SyncStream``

SyncStream Package provides two classes, One is SyncStream which is similar to the swift `AsyncStream` but run in synchronous way. The other is `BidirectionalSyncStream` which is inspired by the generator in python, have the ability to send values back to the stream.

## Overview

### SyncStream

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

### BidirectionalSyncStream

Inspired by the generator in python, which can not only use the `yield` to generate new value, but also can use `send` to sendback value and use `return` to throw `StopIteration` error to stop the stream. The `BidirectionalSyncStream` is a class that provides the same functionality in Swift.

For more information about the generator in python, See: [PEP 255](https://peps.python.org/pep-0255/), [PEP 342](https://peps.python.org/pep-0342/#new-generator-method-send-value), [Doc](https://docs.python.org/3/reference/expressions.html#generator-iterator-methods)

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

```
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

## Topics

### Class

- ``SyncStream-class``
- ``BidirectionalSyncStream``
