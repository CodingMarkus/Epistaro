#!/bin/sh

set -eu

[ -n "${__included_lib_list_sh:-}" ] && return 0
__included_lib_list_sh=1

listTargetsAndExit( )
{
	projectRoot=${PROJECT_ROOT_DIR:-$( pwd -P )}

	for targetDir in "$projectRoot"/targets/*
	do
		[ -d "$targetDir" ] || continue
		printf '%s\n' "$( basename -- "$targetDir" )"
	done
	exit 0
}


listStylesAndExit( )
{
	projectRoot=${PROJECT_ROOT_DIR:-$( pwd -P )}

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
