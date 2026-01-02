BUILD SYSTEM
============

1. Overview
-----------
The build system is driven by the `./proj` wrapper, which dispatches to command scripts in `scripts/`. Commands can be matched by a unique prefix (up to a single letter). When invoked from inside the project tree, build outputs go to `.out/`. When invoked from elsewhere, outputs go to the current working directory.


2. Project Layout
-----------------

- `styles/` holds build style files (documented separately).

- `targets/<name>.lib` and `targets/<name>.bin` define build targets. The extension controls whether the output is a library or a binary.

- `targets/<name>/src/` contains C sources. `targets/<name>/inc/` is used for public headers (libraries only). `targets/<name>/tests/` contains tests.

- `compile_flags.txt` can exist anywhere in the source tree. The nearest file (walking up to the project root) is applied to each source file. The format is one flag per line with `#` comments allowed.


3. Styles
---------
Styles are resolved by name from `styles/<style>.cfg` by default, but you can also pass `styles/<style>.cfg` directly or an absolute path. The default style is `deploy` for `build` and `test` for `test`.


4. Outputs
----------
Build output lives under the build root:

- `builds/<style>/<target>/obj/src/` contains objects and `.dep` files.

- `builds/<style>/<target>/` contains final outputs.

- `.lib` targets produce a static archive (`.a`) and a dynamic library (`.dylib` on Apple platforms, `.dll` on windows, `.so` elsewhere).

- `.bin` targets produce an executable named after the target.

- Library public headers are synced to `builds/<style>/<target>/inc/`.

- `tests/<style>/<target>/bin/` contains test binaries.

- `tests/<style>/<target>/obj/` contains test objects and `.dep` files.


When invoked from inside the project, the build root is `.out/`. When invoked from elsewhere, the build root is the current working directory.


5. Commands
-----------
`./proj build [<style> [<target> ...]]`
    Build all targets or the provided list using the given style. If no style is provided, `deploy` is used.

`./proj test [-s[tyle] <style>] [<target>[/suite[/...][/test]] ...]`
    Build targets (test style by default), then build and run tests. If no target is provided, all targets are tested.

`./proj clean [<style> [<target>]]`
    Remove build output for all builds or a style/target subset. This always cleans `.out/` under the project root.

`./proj list [-plain] targets|styles|tests [<target>]`
    List available targets, styles, or tests. `-plain` prints only names.

`./proj update`
    Update all generated configuration files.

`./proj update config`
    Update build configuration files (currently `.clangd`).

`./proj help [<command>]`
    Print help for one command or all commands.


6. Targets
----------
Target names may be passed with or without the `.lib`/`.bin` suffix. If the name is ambiguous or missing, the build will fail with an error.


7. Tests
--------
Tests live under `targets/<target>/tests/`. Each test directory ends with `.ut` (unit test) or `.it` (integration test). A test selection can point at a test or suite and does not require the `.ut`/`.it` suffix.

- Unit tests link target objects with test objects and execute the result. For `.bin` targets, `main.o` is excluded from the link.

- Integration tests for `.lib` targets build a test binary that links against the target dynamic library, then run it with the library path injected.

- Integration tests for `.bin` targets are script-only and receive the built binary path as an argument.


8. Update Behavior
------------------
`./proj update config` regenerates `.clangd` using `styles/_defaults/_default.cfg` to fill the managed flags section.
