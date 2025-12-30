#!/bin/sh

set -eu

[ -n "${__included_lib_list_sh:-}" ] && return 0
__included_lib_list_sh=1

. lib_assert.sh

# $1 - Project root directory.
#
# Lists available targets (one per line) and exits.
#
listTargetsAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listTargetsAndExit() missing project dir"

	[ -d "$1/targets" ] || exit 0

	find "$1/targets" -mindepth 1 -maxdepth 1 -type d -print \
		2>/dev/null | sed 's#.*/##'
	exit 0
}


# $1 - Project root directory.
#
# Lists available styles (one per line) and exits.
#
listStylesAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listStylesAndExit() missing project dir"

	[ -d "$1/styles" ] || exit 0

	find "$1/styles" -maxdepth 1 -type f -name '*.txt' -print \
		2>/dev/null | sed -e 's#.*/##' -e 's/\.txt$//' -e '/^_/d'
	exit 0
}
