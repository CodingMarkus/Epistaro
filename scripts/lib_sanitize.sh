#!/bin/sh

set -eu

[ -n "${__included_lib_sanitize_sh:-}" ] && return 0
__included_lib_sanitize_sh=1


# $1 - Settings string containing one entry per line.
#
# Prints sanitizer flags (one per line), normalized to -fsanitize=<list>.
#
sanitizeSettingsFromList( )
(
	settings=$1
	prev=""

	if [ -n "$settings" ]
	then
		oldIFS=$IFS
		IFS='
'
		for setting in $settings
		do
			[ -n "$setting" ] || continue
			if [ -n "$prev" ]
			then
				printf '%s\n' "-fsanitize=$setting"
				prev=""
				continue
			fi
			case "$setting" in
				-fsanitize=*) printf '%s\n' "$setting" ;;
				-fsanitize) prev=1 ;;
			esac
		done
		IFS=$oldIFS
	fi
)


# $1 - Quoted settings string.
#
# Prints sanitizer flags (one per line), normalized to -fsanitize=<list>.
#
sanitizeSettingsFromQuoted( )
(
	settings=$1
	prev=""

	[ -n "$settings" ] || return 0

	eval "set -- $settings"
	while [ "$#" -gt 0 ]
	do
		flag=$1
		shift
		if [ -n "$prev" ]
		then
			printf '%s\n' "-fsanitize=$flag"
			prev=""
			continue
		fi
		case "$flag" in
			-fsanitize=*) printf '%s\n' "$flag" ;;
			-fsanitize) prev=1 ;;
		esac
	done
)


# $1 - Build sanitizer settings list.
# $2 - Target sanitizer settings list.
# $3 - Sanitizer flag.
#
# Prints updated target sanitizer list if not already present or in build
# settings.
#
addTargetSanitizeSetting( )
{
	_ats_build=$1
	_ats_target=$2
	_ats_flag=$3

	[ -n "$_ats_flag" ] || {
		printf '%s' "$_ats_target"
		return 0
	}

	case "
$_ats_build
" in
		*"
$_ats_flag
"*) printf '%s' "$_ats_target"; return 0 ;;
	esac

	case "
$_ats_target
" in
		*"
$_ats_flag
"*) printf '%s' "$_ats_target"; return 0 ;;
	esac

	if [ -n "$_ats_target" ]
	then
		printf '%s\n%s' "$_ats_target" "$_ats_flag"
	else
		printf '%s' "$_ats_flag"
	fi
}
