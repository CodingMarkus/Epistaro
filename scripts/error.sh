#!/bin/sh

set -eu

[ -n "${__included_error_sh:-}" ] && return 0
__included_error_sh=1


. scripts/assert.sh


# $1 - The error text to print.
#
printError( )
{
	assert "[ -n \"${1:-}\" ]" "printError() missing message"

	printf 'Error: %s\n' "$1" >&2
}


# $1 - The error text to print.
#
printErrorAndExit( )
{
	assert "[ -n \"${1:-}\" ]" "printErrorAndExit() missing message"

	printError "$1"
	exit 1
}
