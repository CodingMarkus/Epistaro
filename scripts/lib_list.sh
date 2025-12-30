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
	projectRoot=$1

	assert "[ -n \"${projectRoot:-}\" ]" \
		"listTargetsAndExit() missing project dir"

	for targetDir in "$projectRoot"/targets/*
	do
		[ -d "$targetDir" ] || continue
		printf '%s\n' "$( basename -- "$targetDir" )"
	done
	exit 0
}


# $1 - Project root directory.
#
# Lists available styles (one per line) and exits.
#
listStylesAndExit( )
{
	projectRoot=$1

	assert "[ -n \"${projectRoot:-}\" ]" \
		"listStylesAndExit() missing project dir"

	for styleFile in "$projectRoot"/styles/*.txt
	do
		[ -f "$styleFile" ] || continue
		styleName=$( basename -- "$styleFile" .txt )
		case $styleName in
			_*) continue ;;
		esac
		printf '%s\n' "$styleName"
	done
	exit 0
}
