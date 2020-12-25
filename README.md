Glob
====

Glob for Swift 5.

![Build Status](https://github.com/Bouke/Glob/workflows/Test/badge.svg)

# Usage

```swift
let files = Glob(pattern: "./**/*.swift")
for file in files {
    print(file)
}
```

# Credits

Adapted from [efirestone](https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3).
