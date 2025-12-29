#!/bin/sh

set -eu

[ -n "${__included_quote_sh:-}" ] && return 0
__included_quote_sh=1


. scripts/assert.sh


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
