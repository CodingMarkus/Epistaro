#!/bin/sh

set -eu

[ -n "${__included_lib_sanitize_sh:-}" ] && return 0
__included_lib_sanitize_sh=1


# $1 - Settings string containing one entry per line.
#
# Prints sanitizer flags (one per line), normalized to -fsanitize=<list>.
#
_sanitizeSettingsFromList( )
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
_sanitizeSettingsFromQuoted( )
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


# $1 - Sanitizer flag.
#
# Adds to target sanitizer list if not already present or in build settings.
#
_addTargetSanitizeSetting( )
{
	sanitizeFlag=$1

	[ -n "$sanitizeFlag" ] || return 0

	case "
${__buildSanitizeSettings:-}
" in
		*"
$sanitizeFlag
"*) return 0 ;;
	esac

	case "
${__targetSanitizeSettings:-}
" in
		*"
$sanitizeFlag
"*) return 0 ;;
	esac

	if [ -n "${__targetSanitizeSettings:-}" ]
	then
		__targetSanitizeSettings="$__targetSanitizeSettings
$sanitizeFlag"
	else
		__targetSanitizeSettings=$sanitizeFlag
	fi
}
