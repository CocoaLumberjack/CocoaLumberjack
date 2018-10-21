This document contains helper functions and tricks which helps in migration from external libraries to XCTest.

# Snippets find-and-replace.
## Expecta matchers.

find:
```
expect\((.+?)\).to.equal\((.+?)\)
```

replace:
```
XCTAssertEqualObjects($1, $2)
```

## __auto_type inference.

find:
```
(\w+(?!Mutable)\w+)\s*\*\s*(\w+)\s*=\s*(?!nil)
```

replace:
```
__auto_type $2 = 
```