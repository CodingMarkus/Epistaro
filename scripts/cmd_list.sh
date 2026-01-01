#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


. lib_list.sh


printHelp( )
{
	helpText="
  list t[argets]

      List available targets.

  list s[tyles]

      List available styles.
"
	printf '%s' "$helpText"
}


printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	t|target|targets)
		[ "$#" -eq 1 ] || printHelpAndExit
		listTargetsAndExit "$projDir"
		;;

	s|style|styles)
		[ "$#" -eq 1 ] || printHelpAndExit
		listStylesAndExit "$projDir"
		;;

	-*)
		printHelpAndExit
		;;

	"")
		printHelpAndExit
		;;

esac

printHelpAndExit
