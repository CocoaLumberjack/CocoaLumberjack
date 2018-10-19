This document contains helper functions and tricks which helps in migration from external libraries to XCTest.

For example, Expecta could be migrated by.

```
expect\((.+?)\).to.equal\((.+?)\)
```

with replacement

```
XCTAssertEqualObjects($1, $2)
```