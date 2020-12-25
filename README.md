Glob
====

Glob for Swift 5.

[![Build Status](https://travis-ci.org/Bouke/Glob.svg?branch=master)](https://travis-ci.org/Bouke/Glob)

# Usage

```swift
let files = Glob(pattern: "./**/*.swift")
for file in files {
    print(file)
}
```

# Credits

Adapted from [efirestone](https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3).
