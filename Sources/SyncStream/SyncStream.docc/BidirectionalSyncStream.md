# ``BidirectionalSyncStream``

## Overview

Inspired by the generator in python, which can not only use the `yield` to generate new value, but also can use `send` to sendback value and use `return` to throw `StopIteration` error to stop the stream. The `BidirectionalSyncStream` is a class that provides the same functionality in Swift.

For more information about the generator in python, See: [PEP 255](https://peps.python.org/pep-0255/), [PEP 342](https://peps.python.org/pep-0342/#new-generator-method-send-value), [Doc](https://docs.python.org/3/reference/expressions.html#generator-iterator-methods)

Like the `SyncStream` class, the `BidirectionalSyncStream` also use the  `Continuation` to communicate with the stream. The `Continuation` provides two important method, the `yield(_:)` will yield a element to the stream, and then suspend for a value sended form the stream, the `return(_:)` will close the stream and throw a `StopIteration` error with a return value.

In Stream side, User can use `next()` to start the stream, and this method will return the first yielded value. After the first `next()` invocation, user should to use `send(_:)` to control the stream, this method will send a value back, and then return next yielded value. After the stream is closed, aka the `return(_:)` is invoked, the `send(_:)` or `next()` will throw a `StopIteration` error, user can get the return value from the error.

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

## Topics

### Supporting Types

- ``NoneType``

### Errors

- ``StopIteration``
- ``WrongStreamUse``

### Building a BidirectionalSyncStream

- ``init(_:_:_:_:)``
- ``Continuation``

### Using a BidirectionalSyncStream

- ``next()``
- ``send(_:)``
- ``toSyncStream()``
