BUILD SYSTEM
============

1. Overview
-----------
The build system is driven by the `./proj` wrapper, which dispatches to command scripts in `scripts/`. Commands can be matched by partial names (up to a single letter). When invoked from inside the project tree, build outputs go to `.out/`. When invoked from elsewhere, outputs go to the current working directory.


2. Project Layout
-----------------

- `styles/` holds build style files (documented separately).

- `targets/<name>.lib` and `targets/<name>.bin` define build targets. The extension controls whether the output is a library or a binary.

- `targets/<name>/src/` contains C sources. `targets/<name>/inc/` is used for public headers (libraries only). `targets/<name>/tests/` contains tests.

- `compile_flags.txt` can exist anywhere in the source tree. The nearest file (walking up to the project root) is applied to each source file. The format is one flag per line with `#` comments allowed.


3. Styles
---------
Styles are resolved by name from `styles/<style>.cfg` by default, but you can also pass `styles/<style>.cfg` directly or an absolute path. The default style is `deploy` for `build`, `run` for `run`, and `test` for `test`.


4. Outputs
----------
Build output lives under the build root:

- `builds/<style>/<target>/obj/src/` contains objects and `.dep` files.

- `builds/<style>/<target>/obj/<target>.o` is the single-object prelink for `.lib` targets.

- `builds/<style>/<target>/` contains final outputs.

- `.lib` targets produce `builds/<style>/<target>/<target>.a` and `builds/<style>/<target>/<target>.<lib-ext>` (`.dylib` on Apple platforms, `.dll` on windows, `.so` elsewhere).

- `.bin` targets produce `builds/<style>/<target>/<target>[.<ext>]` (usually no extension or `.exe` on Windows).

- Library public headers are synced to `builds/<style>/<target>/inc/`.

- `tests/<style>/<target>/target/` contains testable target outputs built with `TESTING`, mirroring `builds/<style>/<target>/` (including `obj/src/` and `inc/`).

- `tests/<style>/<target>/bin/` contains test binaries.

- `tests/<style>/<target>/obj/` contains test objects and `.dep` files.


When invoked from inside the project, the build root is `.out/`. When invoked from elsewhere, the build root is the current working directory.


5. Commands
-----------
`./proj build [-s[tyle] <style>] [<target> ...]`
    Build target(s) using a style. If no target is provided, all targets are built. If no style is provided, all targets are built using the `deploy` style.

`./proj run [-s[tyle] <style>] <target> [<arg> ...]`
    Build a binary target using the given style (default `run`) and execute it. Arguments following the target are passed to the binary. Only `.bin` targets are supported.

`./proj test [[-s[tyle] <style>] ...] [<target>[/suite[/...][/test]] ...]`
    Build targets (test style by default), build tests, and run them. Repeat `-s` to test multiple styles in a single run. If no target is provided, all targets are tested. You can scope to a suite or a specific test using a pseudo path, omitting `.ut`/`.it` for specific tests.

`./proj clean [-s[tyle] <style>] [<target> ...]`
    Clean all builds and tests, or only for a style/target subset.

`./proj list [-plain] targets`
    List available targets. `-plain` prints only names.

`./proj list [-plain] styles`
    List available styles. `-plain` prints only names.

`./proj list [-plain] tests [<target>]`
    List available tests for a target, or all targets. `-plain` prints only names.

`./proj update`
    Update all generated configuration files.

`./proj update config`
    Update build configuration files (currently `.clangd`).

`./proj help [<command>]`
    Print help for a command. If no command is specified, print help for all commands.


6. Targets
----------
Target names may be passed with or without the `.lib`/`.bin` suffix. If the name is ambiguous or missing, the build will fail with an error.


7. Tests
--------
Tests live under `targets/<target>/tests/`. Each test directory ends with `.ut` (unit test) or `.it` (integration test). A test selection can point at a test or suite and does not require the `.ut`/`.it` suffix.

- Unit tests link target objects from `tests/<style>/<target>/target/` with test objects and execute the result. For `.bin` targets, `main.o` is excluded from the link.

- Integration tests for `.lib` targets build a test binary that links against the target dynamic library from `tests/<style>/<target>/target/`, then run it with the library path injected.

- Integration tests for `.bin` targets are script-only and receive the built binary path from `tests/<style>/<target>/target/` as an argument.


8. Update Behavior
------------------
`./proj update config` regenerates `.clangd` using `styles/_defaults/_default.cfg` to fill the managed flags section.
