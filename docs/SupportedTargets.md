SUPPORTED TARGETS
=================

TARGET names use the format:

  TARGET=<OS>[-<CPU>]

CPU is reserved for future use. If TARGET is not set, the build uses the
current host OS.

Supported OS values:

- Linux
- macOS
- Windows
- iOS
- tvOS
- iPadOS
- watchOS
- FreeBSD
- NetBSD
- OpenBSD
- Emscripten

Development hosts:

- Linux
- macOS
- *BSD
- Windows (POSIX environments such as Cygwin or MSYS/MinGW)
