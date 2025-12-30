#!/bin/sh

set -eu

origDir=$( pwd -P )
scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
rootDir=$( CDPATH='' cd -- "$scriptDir/.." && pwd -P )

cd "$scriptDir"
PROJECT_ROOT_DIR=$rootDir

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
	-help|-h|--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

printErrorAndExit "Test runner not configured"
