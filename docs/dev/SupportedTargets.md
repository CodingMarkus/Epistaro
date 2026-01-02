TARGETS
=======

TARGET names use the format:

    TARGET=<os>-<cpu>

If TARGET is not set, the build uses the current host OS and CPU when it can detect them.

The scripts do not restrict OS/CPU combinations, but only some are meaningful today.

Supported OSes
--------------

- linux (glibc 2.17+ or musl 1.2+, kernel 3.10+)
- macos (10.9+)
- windows (Vista SP2+ or Server 2008 SP2+)
- ios (12+)
- tvos (12+)
- ipados (13+)
- watchos (6+)
- freebsd (13.2+)
- netbsd (9.3+)
- openbsd (7.3+)
- emscripten (3.1+)


### Notes:

- Linux baseline is largely defined by the libc ABI; musl builds are supported and encouraged for minimal container images (e.g. Alpine).

- Pre-Windows 10 targets require UCRT support to be installed (KB2999226).
  Supported Vista/7/8/8.1 systems should receive this via Windows Update; for
  older or offline systems, download installer from here:
  https://support.microsoft.com/en-us/topic/update-for-universal-c-runtime-in-windows-c0514201-7fe6-95a3-b0a5-287930f3560c?utm_source=chatgpt.com


Supported CPUs
--------------

| Target name | Meaning / minimum contract                                                           |
| ----------- | ------------------------------------------------------------------------------------ |
| `arm64`     | AArch64 (ARMv8+ 64-bit). FP/ASIMD (NEON) is part of the baseline.                    |
| `arm32vfp3` | 32-bit ARM, intended as ARMv7-A baseline with hardware VFPv3 (no VFPv4 requirement). |
| `ia32sse2`  | 32-bit x86 with at least SSE2; use SSE FP math (avoid x87 assumptions).              |
| `x64`       | x86-64 in 64-bit mode (AMD64 / x86-64). SSE2 is baseline.                            |
| `wasm32`    | WebAssembly 32-bit output target.                                                    |
| `asmjs`     | asm.js output (Emscripten-style JS subset) target.                                   |


Meaningful Targe Combinations
-----------------------------

- linux
  - x64
  - ia32sse2 (requires SSE2-capable CPU and OS support)
  - arm64
  - arm32vfp3
- macos
  - x64 (supported since Mac OS X 10.4.4)
  - arm64 (supported since macOS 11)
- windows
  - x64 (supported since Windows XP Professional x64 Edition / Server 2003 x64)
  - ia32sse2 (supported since Windows XP)
  - arm64 (supported since Windows 10 on ARM)
- ios
  - arm64 (supported since iOS 7)
- tvos
  - arm64 (supported since tvOS 9)
- ipados
  - arm64 (supported since iPadOS 13)
- watchos
  - arm64
- freebsd
  - x64
  - arm64
- netbsd
  - x64
- openbsd
  - x64
- emscripten
  - wasm32
  - asmjs
