SUPPORTED TARGETS
=================

TARGET names use the format:

  TARGET=<os>-<cpu>

If TARGET is not set, the build uses the current host OS and CPU when it can detect them.

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

Supported CPU values:

| Target name | Meaning / minimum contract                                                           |
| ----------- | ------------------------------------------------------------------------------------ |
| `arm64`     | AArch64 (ARMv8+ 64-bit). FP/ASIMD (NEON) is part of the baseline.                    |
| `arm32vfp3` | 32-bit ARM, intended as ARMv7-A baseline with hardware VFPv3 (no VFPv4 requirement). |
| `ia32sse2`  | 32-bit x86 with at least SSE2; use SSE FP math (avoid x87 assumptions).              |
| `x64`       | x86-64 in 64-bit mode (AMD64 / x86-64). SSE2 is baseline.                            |
| `wasm32`    | WebAssembly 32-bit output target.                                                    |
| `asmjs`     | asm.js output (Emscripten-style JS subset) target.                                   |

Development hosts:

- linux
- macos
- *bsd
- windows (POSIX environment required such as Cygwin or MSYS/MinGW)

Compiler requirements:

- The build requires clang. Other compilers are not supported.
- Windows builds require a mingw-64 clang toolchain.
