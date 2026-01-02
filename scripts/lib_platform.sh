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
		case "$( uname -s 2>/dev/null )" in
			Linux) printf '%s\n' "Linux" ;;
			Darwin) printf '%s\n' "macOS" ;;
			FreeBSD) printf '%s\n' "FreeBSD" ;;
			NetBSD) printf '%s\n' "NetBSD" ;;
			OpenBSD) printf '%s\n' "OpenBSD" ;;
			CYGWIN*|MINGW*|MSYS*|Windows_NT)
				printf '%s\n' "Windows"
				;;
			Emscripten) printf '%s\n' "Emscripten" ;;
		esac
	fi
	return 0
}


# Initializes __style_set__TARGET* variables for style expansion.
#
# TARGET format: <OS>[-<CPU>]. CPU parsing is reserved for future use.
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
			;;
		"")
			__style_set__TARGET_OS=""
			__style_set__TARGET_CPU=""
			;;
		*)
			__style_set__TARGET_OS=$__style_set__TARGET
			__style_set__TARGET_CPU=""
			;;
	esac
}


# Returns success if the target OS is an Apple platform.
#
platformTargetIsApple( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		macOS|iOS|tvOS|iPadOS|watchOS) return 0 ;;
		*) return 1 ;;
	esac
}


# Returns success if the target OS is Windows.
#
platformTargetIsWindows( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		Windows) return 0 ;;
		*) return 1 ;;
	esac
}


# Returns success if the target OS is supported.
#
platformTargetIsSupported( )
{
	platformInitTargetVars
	case "${__style_set__TARGET_OS:-}" in
		Linux|macOS|Windows|iOS|tvOS|iPadOS|watchOS|\
		FreeBSD|NetBSD|OpenBSD|Emscripten)
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
Linux, macOS, Windows, iOS, tvOS, iPadOS, watchOS, FreeBSD, NetBSD, OpenBSD, \
Emscripten."
}


platformInitTargetVars
