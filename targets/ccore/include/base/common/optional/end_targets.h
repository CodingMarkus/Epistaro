#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _targetsActive
		#error end_targets.h included without including targets.h first
	#endif
#endif
#undef _targetsActive

// ============================================================================
// CPU Byte Order

#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
	#define CPU_IS_BIG_ENDIAN 1
#elif __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
	#define CPU_IS_LITTLE_ENDIAN 1
#else
	#error Failed to detect byte order
#endif

// ============================================================================
// CPU Architecture

#if defined(__x86_64__) || defined(__amd64__)
	#define CPU_ARCH_IS_AMD64 1
	#define CPU_IS_64_BIT 1
#elif defined(__i386__)
	#define CPU_ARCH_IS_X86 1
	#define CPU_IS_32_BIT 1
#elif defined(__aarch64__)
	#define CPU_ARCH_IS_ARM64 1
	#define CPU_IS_64_BIT 1
#elif defined(__arm__) || defined(_M_ARM)
	#define CPU_ARCH_IS_ARM 1
	#define CPU_IS_32_BIT 1
#elif defined(__powerpc64__)
	#define CPU_ARCH_IS_PPC64 1
	#define CPU_IS_64_BIT 1
#elif defined(__powerpc__)
	#define CPU_ARCH_IS_PPC 1
	#define CPU_IS_32_BIT 1
#elif defined(__riscv)
	#if __riscv_xlen == 64
		#define CPU_ARCH_RV64 1
		#define CPU_IS_64_BIT 1
	#elif __riscv_xlen == 32
		#define CPU_ARCH_RV32 1
		#define CPU_IS_32_BIT 1
	#else
		#error Unsupported RISC-V XLEN
	#endif
#else
	#error Failed to detect CPU architecture
#endif

// ============================================================================
// OS

#if defined(__APPLE__) && defined(__MACH__)
	#define OS_IS_DARWIN_BASED 1
	#define OS_HAS_POSIX_API 1
	#include <TargetConditionals.h>
	#if TARGET_OS_OSX
		#define OS_IS_MACOS 1
	#elif TARGET_OS_IPHONE && TARGET_OS_IOS
		#define OS_IS_IOS 1
	#elif TARGET_OS_IPHONE && TARGET_OS_TV
		#define OS_IS_TVOS 1
	#elif TARGET_OS_WATCH
		#define OS_IS_WATCHOS 1
	#else
		#error Unknown Apple OS
	#endif
#elif defined(_WIN32)
	#define OS_IS_WINDOWS 1
#elif defined(__ANDROID__)
	#define OS_IS_ANDROID 1
	#define OS_HAS_POSIX_API 1
#elif defined(__EMSCRIPTEN__)
	#define OS_IS_WEB 1
	#define OS_HAS_POSIX_API 1
#elif defined(__linux__)
	#define OS_IS_LINUX 1
	#define OS_HAS_POSIX_API 1
#elif defined(__FreeBSD__)
	#define OS_IS_FREEBSD 1
	#define OS_HAS_POSIX_API 1
#elif defined(__OpenBSD__)
	#define OS_IS_OPENBSD 1
	#define OS_HAS_POSIX_API 1
#elif defined(__NetBSD__)
	#define OS_IS_NETBSD 1
	#define OS_HAS_POSIX_API 1
#elif defined(__unix__) || defined(__unix) \
		|| defined(_POSIX_VERSION) || defined(_POSIX_SOURCE) \
		|| defined(_XOPEN_SOURCE)
	#define OS_IS_POSIX_BASED 1
	#define OS_HAS_POSIX_API 1
#else
	#error Failed to detect OS
#endif
