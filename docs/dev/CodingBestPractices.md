CODING BEST PRACTICES
=====================

1. require() vs assert()
------------------------
Use `require()` when a condition must always hold and violating it would create severe consequences in production, such as data loss, corruption, or security vulnerabilities. In those cases, the program should fail fast instead of continuing in a compromised state.

Use `assert()` for invariants that are valuable during development and testing but should not crash release builds. Overusing `require()` can make systems brittle and adds runtime cost. Avoid always-on checks in hot paths when the condition can only fail due to internal bugs that are already under your control.
