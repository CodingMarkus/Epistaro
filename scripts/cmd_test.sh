#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"

. lib_error.sh

printHelp( )
{
	helpText="
  test

      Run project tests.


  test -h[elp]

      Show this help screen.
"
	printf '%s' "$helpText"
}


printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


case "${1:-}" in
	-help|-h)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

printErrorAndExit "Test runner not configured"
