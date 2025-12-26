#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _targetsActive
		#error end_targets.h included without including targets.h first
	#endif
#endif
#undef _targetsActive

// ============================================================================

#ifdef CPU_IS_BIG_ENDIAN
	#undef CPU_IS_BIG_ENDIAN
#endif
#ifdef CPU_IS_LITTLE_ENDIAN
	#undef CPU_IS_LITTLE_ENDIAN
#endif


// ============================================================================
// CPU Architecture

#ifdef CPU_ARCH_IS_AMD64
	#undef CPU_ARCH_IS_AMD64
#endif
#ifdef CPU_ARCH_IS_X86
	#undef CPU_ARCH_IS_X86
#endif
#ifdef CPU_ARCH_IS_ARM64
	#undef CPU_ARCH_IS_ARM64
#endif
#ifdef CPU_ARCH_IS_ARM
	#undef CPU_ARCH_IS_ARM
#endif
#ifdef CPU_ARCH_IS_PPC64
	#undef CPU_ARCH_IS_PPC64
#endif
#ifdef CPU_ARCH_IS_PPC
	#undef CPU_ARCH_IS_PPC
#endif
#ifdef CPU_ARCH_RV64
	#undef CPU_ARCH_RV64
#endif
#ifdef CPU_ARCH_RV32
	#undef CPU_ARCH_RV32
#endif


#ifdef CPU_IS_64_BIT
	#undef CPU_IS_64_BIT
#endif
#ifdef CPU_IS_32_BIT
	#undef CPU_IS_32_BIT
#endif


// ============================================================================
// OS

#ifdef OS_IS_DARWIN_BASED
	#undef OS_IS_DARWIN_BASED
#endif
#ifdef OS_IS_MACOS
	#undef OS_IS_MACOS
#endif
#ifdef OS_IS_IOS
	#undef OS_IS_IOS
#endif
#ifdef OS_IS_TVOS
	#undef OS_IS_TVOS
#endif
#ifdef OS_IS_WATCHOS
	#undef OS_IS_WATCHOS
#endif
#ifdef OS_IS_WINDOWS
	#undef OS_IS_WINDOWS
#endif
#ifdef OS_IS_ANDROID
	#undef OS_IS_ANDROID
#endif
#ifdef OS_IS_WEB
	#undef OS_IS_WEB
#endif
#ifdef OS_IS_LINUX
	#undef OS_IS_LINUX
#endif
#ifdef OS_IS_FREEBSD
	#undef OS_IS_FREEBSD
#endif
#ifdef OS_IS_OPENBSD
	#undef OS_IS_OPENBSD
#endif
#ifdef OS_IS_NETBSD
	#undef OS_IS_NETBSD
#endif
#ifdef OS_IS_POSIX_BASED
	#undef OS_IS_POSIX_BASED
#endif


#ifdef OS_HAS_POSIX_API
	#undef OS_HAS_POSIX_API
#endif
