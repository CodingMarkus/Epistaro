#!/bin/sh

set -eu

[ -n "${__included_lib_assert_sh:-}" ] && return 0
__included_lib_assert_sh=1

# $1 - condition to be asserted.
# ($2) - Optional error message to print
#
# Does nothing if assertion is met.
# Ends script with error if assertion fails.
#
assert( )
{
	if [ -z "${1:-}" ]
	then
		printf 'Error: %s\n' "assert() missing condition" >&2
		exit 1
	fi

	eval "$1" && return 0

	if [ -n "${2:-}" ]
	then
		printf 'Error: Assertion failed: %s (%s)\n' "$2" "$1" >&2
		exit 1
	fi

	printf 'Error: Assertion failed: %s\n' "$1" >&2
	exit 1
}
