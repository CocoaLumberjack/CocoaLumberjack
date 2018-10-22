This document contains helper functions and tricks which helps in migration from external libraries to XCTest.

# Snippets find-and-replace
## Expecta matchers

find:
```perl
"expect\((.+?)\).to.equal\((.+?)\)"
```

replace:
```perl
"XCTAssertEqualObjects($1, $2)"
```

## __auto_type inference

find:
```perl
"(\w+(?!Mutable)\w+)\s*\*\s*(\w+)\s*=\s*(?!nil)"
```

replace: ( notice trailing space. it is necessary to not break existing formatting )
```perl
"__auto_type $2 = "
```