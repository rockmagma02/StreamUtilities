# ``SyncStream/SyncStream/Continuation``

## Overview

The Closure you provide to the `SyncStream` in `init(_:_:)` received an instance of this type when called. Use this continuation to yield element via method `yield(_)`, and finish the stream via method `finish()`.

## Topics

### Producing Elements

- ``yield(_:)``

### Finish the Stream

- ``finish()``
