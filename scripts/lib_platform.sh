#!/bin/sh

set -eu

[ -n "${__included_lib_platform_sh:-}" ] && return 0
__included_lib_platform_sh=1


. lib_error.sh


# Prints the host OS name mapped to supported TARGET values.
#
platformDetectHostOs( )
{
	if command -v uname >/dev/null 2>&1
	then
		uname_s=$( uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' )
		case "$uname_s" in
			linux) printf '%s\n' "linux" ;;
			darwin) printf '%s\n' "macos" ;;
			freebsd) printf '%s\n' "freebsd" ;;
			netbsd) printf '%s\n' "netbsd" ;;
			openbsd) printf '%s\n' "openbsd" ;;
			cygwin*|mingw*|msys*|windows_nt)
				printf '%s\n' "windows"
				;;
			emscripten) printf '%s\n' "emscripten" ;;
		esac
	fi
	return 0
}


# Prints the host CPU name mapped to supported TARGET values.
#
platformDetectHostCpu( )
{
	if command -v uname >/dev/null 2>&1
	then
		uname_m=$( uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]' )
		case "$uname_m" in
			aarch64|arm64) printf '%s\n' "arm64" ;;
			armv7*) printf '%s\n' "arm32vfp3" ;;
			i386|i486|i586|i686) printf '%s\n' "ia32sse2" ;;
			x86_64|amd64) printf '%s\n' "x64" ;;
			wasm32) printf '%s\n' "wasm32" ;;
			asmjs) printf '%s\n' "asmjs" ;;
		esac
	fi
	return 0
}


# Initializes __style_set__TARGET* variables for style expansion.
#
# TARGET format: <os>-<cpu>.
#
platformInitTargetVars( )
{
	[ -n "${__platform_target_vars_ready:-}" ] && return 0
	__platform_target_vars_ready=1

	if [ -n "${TARGET:-}" ]
	then
		__style_set__TARGET=$TARGET
	else
		__style_set__TARGET_OS=$( platformDetectHostOs )
		__style_set__TARGET_CPU=$( platformDetectHostCpu )
		if [ -n "${__style_set__TARGET_OS:-}" ]
		then
			if [ -n "${__style_set__TARGET_CPU:-}" ]
			then
				__style_set__TARGET=\
${__style_set__TARGET_OS}-${__style_set__TARGET_CPU}
			else
				__style_set__TARGET=$__style_set__TARGET_OS
			fi
		else
			__style_set__TARGET=""
		fi
	fi

	case "${__style_set__TARGET:-}" in
		*-*)
			__style_set__TARGET_OS=${__style_set__TARGET%%-*}
			__style_set__TARGET_CPU=${__style_set__TARGET#*-}
			__style_set__TARGET_OS=$( \
				printf '%s' "$__style_set__TARGET_OS" \
					| tr '[:upper:]' '[:lower:]' )
			__style_set__TARGET_CPU=$( \
				printf '%s' "$__style_set__TARGET_CPU" \
					| tr '[:upper:]' '[:lower:]' )
			__style_set__TARGET=\
${__style_set__TARGET_OS}-${__style_set__TARGET_CPU}
			;;
		"")
			__style_set__TARGET_OS=""
			__style_set__TARGET_CPU=""
			;;
		*)
			__style_set__TARGET_OS=$__style_set__TARGET
			__style_set__TARGET_CPU=""
			__style_set__TARGET_OS=$( printf '%s' "$__style_set__TARGET_OS" | \
				tr '[:upper:]' '[:lower:]' )
			__style_set__TARGET=$__style_set__TARGET_OS
			;;
	esac
}


# Returns success if the target OS is an Apple platform.
#
platformTargetIsApple( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		macos|ios|tvos|ipados|watchos) return 0 ;;
		*) return 1 ;;
	esac
}


# Returns success if the target OS is windows.
#
platformTargetIsWindows( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		windows) return 0 ;;
		*) return 1 ;;
	esac
}


# Returns success if the target CPU is supported or unspecified.
#
platformTargetCpuIsSupported( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_CPU:-}" in
		arm64|arm32vfp3|ia32sse2|x64|wasm32|asmjs) return 0 ;;
		*) return 1 ;;
	esac
}


# Returns success if the target OS is supported.
#
platformTargetIsSupported( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		linux|macos|windows|ios|tvos|ipados|watchos|\
		freebsd|netbsd|openbsd|emscripten)
			;;
		*) return 1 ;;
	esac
	platformTargetCpuIsSupported
}


# Fails if the target OS or CPU is not recognized.
#
platformRequireSupportedTarget( )
{
	platformInitTargetVars
	if [ -z "${__style_set__TARGET_OS:-}" ]
	then
		printErrorAndExit \
			"Target OS not detected. Set TARGET to a supported OS."
	fi

	if [ -z "${__style_set__TARGET_CPU:-}" ]
	then
		printErrorAndExit \
			"Target CPU not detected. Set TARGET to a supported os-cpu pair."
	fi

	case "${__style_set__TARGET_OS:-}" in
		linux|macos|windows|ios|tvos|ipados|watchos|\
		freebsd|netbsd|openbsd|emscripten)
			;;
		*)
			printErrorAndExit \
				"Unsupported target OS: ${__style_set__TARGET_OS}. "\
"Supported OSes: linux, macos, windows, ios, tvos, "\
"ipados, watchos, freebsd, netbsd, openbsd, emscripten."
			;;
	esac

	if ! platformTargetCpuIsSupported
	then
		printErrorAndExit \
			"Unsupported target CPU: ${__style_set__TARGET_CPU}. "\
"Supported CPUs: arm64, arm32vfp3, ia32sse2, x64, wasm32, asmjs."
	fi

	return 0
}


platformInitTargetVars
