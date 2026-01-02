SUPPORTED DEVELOPMENT HOSTS
===========================

- linux (glibc 2.17+ or musl 1.2+, kernel 3.10+)
- macos (10.9+; MacPorts clang acceptable)
- windows (10+; POSIX environment required such as Cygwin or MSYS/MinGW)
- freebsd (13.2+)
- netbsd (9.3+)
- openbsd (7.3+)

Notes:

- Building Apple platform binaries with Xcode SDKs may require a higher macOS
  host baseline than 10.9.

Compiler requirements
---------------------

- Building requires clang. Other compilers are not supported.
- Development hosts must provide clang and clangd version 10.0.0 or newer. Newer
  versions are recommended.
- Windows builds require a mingw-w64 clang toolchain.
