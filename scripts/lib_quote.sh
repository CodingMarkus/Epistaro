#!/bin/sh

set -eu

[ -n "${__included_lib_quote_sh:-}" ] && return 0
__included_lib_quote_sh=1

. lib_assert.sh

# $1 - A string to be quoted so it is safe to be used as shell argument.
#
# Prints quoted string.
#
quote( )
{
	assert "[ -n \"${1:-}\" ]" "quote() missing input"

    # Replace each single quote with: '\'' (close, escape, reopen).
    printf "'%s'" "$( printf "%s" "$1" | sed "s/'/'\\\\''/g" )"
}


# $1 - Settings string containing one entry per line.
#
# Prints a single string with each setting shell-quoted and space-delimited.
#
quoteSettings( )
(
	settings=$1

	output=""
	if [ -n "$settings" ]
	then
		oldIFS=$IFS
		IFS='
'
		for setting in $settings
		do
			quoted=$( quote "$setting" )
			if [ -z "$output" ]
			then
				output=$quoted
			else
				output="$output $quoted"
			fi
		done
		IFS=$oldIFS
	fi

	printf '%s' "$output"
)
