#!/bin/sh

set -eu

[ -n "${__included_style_sh:-}" ] && return 0
__included_style_sh=1


. scripts/error.sh
. scripts/assert.sh


# $1 - Build style file path.
#
# Prints expanded build styles
#
expandStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" "expandStyle() missing style path"
	assert "[ -e \"$stylePath\" ]" "style file not found: $stylePath"

	case "$stylePath" in
		*/*) styleDir=${stylePath%/*} ;;
		*) styleDir="." ;;
	esac

	while IFS= read -r line || [ -n "$line" ]; do
		trimmed=$( printf '%s' "$line" | sed 's/^[[:space:]]*//' )
		[ -z "$trimmed" ] && continue

		case "$trimmed" in
			\#*) continue ;;
			\$include[[:space:]]* )
				includeLine=${trimmed#\$include}
				includeName=$( printf '%s' "$includeLine" \
					| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' )
				if [ -z "$includeName" ]
				then
					printErrorAndExit "\$include missing name in $stylePath"
				fi
				includePath="$styleDir/$includeName"
				if [ ! -e "$includePath" ]
				then
					printErrorAndExit "\$include style not found: $includeName"
				fi
				expandStyle "$styleDir/$includeName"
				;;
			\$*)
				printErrorAndExit "Unknown directive in $stylePath: $trimmed"
				;;
			*)
				printf '%s\n' "$trimmed"
				;;
		esac
	done < "$stylePath"
)
