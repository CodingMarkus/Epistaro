#!/bin/sh

set -eu

[ -n "${__included_lib_link_sh:-}" ] && return 0
__included_lib_link_sh=1


. lib_platform.sh
. lib_quote.sh
. lib_sanitize.sh


# Prints the dynamic library extension for the current platform.
#
dynamicLibExtension( )
{
	if platformTargetIsApple
	then
		printf '%s\n' ".dylib"
	elif platformTargetIsWindows
	then
		printf '%s\n' ".dll"
	else
		printf '%s\n' ".so"
	fi
}


# Prints linker flags for deploy post-processing.
#
_deployPostprocessFlags( )
{
	if platformTargetIsApple
	then
		printf '%s\n' "-Wl,-dead_strip"
		printf '%s\n' "-Wl,-S"
		printf '%s\n' "-Wl,-x"
	else
		printf '%s\n' "-Wl,--gc-sections"
		printf '%s\n' "-Wl,--strip-debug"
	fi
}


# $1 - Quoted build settings string.
# $2 - Target sanitizer settings list.
#
# Prints quoted sanitizer flags for linking.
#
_linkSanitizeFlagsFromSettings( )
(
	_lsf_build_settings=$1
	_lsf_target_sanitize=$2

	_lsf_build_sanitize=$( sanitizeSettingsFromQuoted \
		"$_lsf_build_settings" )
	_lsf_link_sanitize=$_lsf_build_sanitize
	if [ -n "$_lsf_target_sanitize" ]
	then
		while IFS= read -r _lsf_flag || [ -n "$_lsf_flag" ]
		do
			[ -n "$_lsf_flag" ] || continue
			_lsf_link_sanitize=$(
				addTargetSanitizeSetting \
					"$_lsf_build_sanitize" \
					"$_lsf_link_sanitize" \
					"$_lsf_flag"
			)
		done <<EOF
$_lsf_target_sanitize
EOF
	fi

	if [ -n "$_lsf_link_sanitize" ]
	then
		quoteSettings "$_lsf_link_sanitize"
	fi
)


# $1 - Quoted build settings string.
# $2 - Target sanitizer settings list.
# $3 - Include deploy post-processing flags when set to 1.
#
# Prints quoted link flags.
#
linkFlagsFromSettings( )
(
	_lf_settings=$1
	_lf_target_sanitize=$2
	_lf_include_deploy=${3:-0}

	_lf_flags=""
	_lf_sanitize=$( _linkSanitizeFlagsFromSettings \
		"$_lf_settings" "$_lf_target_sanitize" )
	if [ -n "$_lf_sanitize" ]
	then
		_lf_flags=$( appendQuotedSettings \
			"$_lf_flags" "$_lf_sanitize" )
	fi

	if [ "$_lf_include_deploy" -eq 1 ] \
		&& [ -n "${__style_set_DEPLOY_PROCESSING+x}" ]
	then
		_lf_post=$( _deployPostprocessFlags )
		if [ -n "$_lf_post" ]
		then
			_lf_post_quoted=$( quoteSettings "$_lf_post" )
			_lf_flags=$( appendQuotedSettings \
				"$_lf_flags" "$_lf_post_quoted" )
		fi
	fi

	[ -n "$_lf_flags" ] || _lf_flags="--"
	printf '%s\n' "$_lf_flags"
)
