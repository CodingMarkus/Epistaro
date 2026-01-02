SUPPORTED TARGETS
=================

TARGET names use the format:

  TARGET=<os>[-<CPU>]

CPU is reserved for future use. If TARGET is not set, the build uses the
current host OS.

Supported OS values:

- linux
- macos
- windows
- ios
- tvos
- ipados
- watchos
- freebsd
- netbsd
- openbsd
- emscripten

Development hosts:

- linux
- macos
- *bsd
- windows (POSIX environments such as Cygwin or MSYS/MinGW)

Compiler requirements:

- The build requires clang. Other compilers are not supported.
- Windows builds require a mingw-64 clang toolchain.
