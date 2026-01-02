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


# Initializes __style_set__TARGET* variables for style expansion.
#
# TARGET format: <os>[-<CPU>]. CPU parsing is reserved for future use.
#
platformInitTargetVars( )
{
	[ -n "${__platform_target_vars_ready:-}" ] && return 0
	__platform_target_vars_ready=1

	if [ -n "${TARGET:-}" ]
	then
		__style_set__TARGET=$TARGET
	else
		__style_set__TARGET=$( platformDetectHostOs )
	fi

	case "${__style_set__TARGET:-}" in
		*-*)
			__style_set__TARGET_OS=${__style_set__TARGET%%-*}
			__style_set__TARGET_CPU=${__style_set__TARGET#*-}
			__style_set__TARGET_OS=$( printf '%s' "$__style_set__TARGET_OS" | \
				tr '[:upper:]' '[:lower:]' )
			__style_set__TARGET=${__style_set__TARGET_OS}-${__style_set__TARGET_CPU}
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


# Returns success if the target OS is supported.
#
platformTargetIsSupported( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		linux|macos|windows|ios|tvos|ipados|watchos|\
		freebsd|netbsd|openbsd|emscripten)
			return 0
			;;
		*) return 1 ;;
	esac
}


# Fails if the target OS is not recognized.
#
platformRequireSupportedTarget( )
{
	platformInitTargetVars
	if platformTargetIsSupported
	then
		return 0
	fi

	if [ -z "${__style_set__TARGET_OS:-}" ]
	then
		printErrorAndExit \
			"Target OS not detected. Set TARGET to a supported OS."
	fi

	printErrorAndExit \
		"Unsupported target OS: ${__style_set__TARGET_OS}. Supported OSes: \
linux, macos, windows, ios, tvos, ipados, watchos, freebsd, netbsd, openbsd, \
emscripten."
}


platformInitTargetVars
