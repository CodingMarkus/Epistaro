#!/bin/sh

set -eu

[ -n "${__included_list_sh:-}" ] && return 0
__included_list_sh=1


listTargetsAndExit( )
{
	for targetDir in targets/*
	do
		[ -d "$targetDir" ] || continue
		printf '%s\n' "$( basename -- "$targetDir" )"
	done
	exit 0
}


listStylesAndExit( )
{
	for styleFile in styles/*.txt
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
