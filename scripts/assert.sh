#!/bin/sh

set -eu

[ -n "${__included_assert_sh:-}" ] && return 0
__included_assert_sh=1



# $1 - condition to be asserted.
# ($2) - Optional error message to print
#
# Does nothing if assertion is met.
# Ends script with error if assertion fails.
#
assert( )
{
	cond=$1
	msg=${2:-}

	if [ -z "$cond" ]
	then
		printf 'Error: %s\n' "assert() missing condition" >&2
		exit 1
	fi

	eval "$cond" && return 0

	if [ -n "$msg" ]
	then
		printf 'Error: Assertion failed: %s (%s)\n' "$msg" "$cond" >&2
		exit 1
	fi

	printf 'Error: Assertion failed: %s\n' "$cond" >&2
	exit 1
}
