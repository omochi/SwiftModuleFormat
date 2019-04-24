# SwiftModuleFormat

A description of this package.

# Development

## Porting base revision

```
commit 904ba9bafe1f0a59c52ad8eda014a504163c98f3 (HEAD -> master)
Author: Kuba (Brecka) Mracek <mracek@apple.com>
Date:   Sun Apr 21 18:16:48 2019 -0700

Undo "Disable TSan in coroutine functions" (0ca3f79). (#23952)

This is no longer needed because we now make sure to run the coroutine lowering pass before ASan/TSan instrumentation passes.

Also fixes a typo in the test.
```
