# Development Goals

These goals define the guiding principles for all Epistaro development. They ensure consistent design, maintainability, and simplicity across all components. Deviations from these principles require explicit justification during code review.


## 1. Target clang C Compiler Exclusively

The goal is not to produce ISO-C compatible code or code that can be built with various C compilers, such as gcc or MSVC. The code only has to compile with clang and thus may make heavy use of clang C extensions.

clang has proven to be a very powerful, performant C compiler that offers many non-standard C extensions, which make code much more pleasant to write, easier to read, and better to maintain.


## 2. Avoid Unnecessary Runtime Dependencies

Unless absolutely necessary, the code shall not depend on any external library, system or otherwise. This ensures that the final product can run literally everywhere without first having to install a ton of dependencies.

Of course, you should not implement your own TLS library, but if you need a non-cryptographic hash function, include a minimal implementation directly in the project instead of adding a dependency on a large external library just for that purpose.


## 3. Minimal Build Dependencies

Other than clang, the only required build tools are a POSIX-conforming shell running build scripts.


## 4. Filesystem as Database

The file system is the database. Modern file systems are highly optimized and may even have been designed explicitly for storing data to certain hardware devices, often doing a much better job than generic database implementations. They are fast, efficient, and actually often do work like databases internally.

Databases often have a huge memory overhead, would be an unnecessary dependency, require external tools to be accessed by the user in terminal, cannot easily be repaired if corrupted, and will often provide no real-world performance benefit anyway over using optimized file storage. State and metadata are persisted as structured files for transparency and repairability.


## 5. Prioritize Beautiful and Readable Code

Keeping code simple, readable, maintainable, and extendible is more important than compact code, fast performance, low memory footprint, or CPU usage. Unless performance is really proven to be affected by this, everything else is premature optimization. Code readability and structure are reviewed as strictly as functionality. Prefer simplicity over cleverness. Implement only what is required today.


## 6. Minimalistic Standard Compliance

While protocol implementations must not violate the standards, they should only implement what the standard absolutely demands. Everything optional is left out, unless there is a justifiable reason why the code should support it. Optional protocol features are excluded unless required for interoperability and documented explicitly when added.


## 7. Test Driven Development and Coverage

Develop with testability in mind. Any function should have a unit test. This is not to prove that functions do work correctly as you cannot prove that by testing (as then you would have to test any possible input/output data combination possible, which would be endless combinations for most functions). It is to detect when a change obviously has broken a function.

Also, every time a bug has been fixed that was not detected by a unit test, write a new unit test that would have found this bug, so the bug is detected in case of a regression.