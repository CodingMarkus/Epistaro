#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


. lib_clean.sh


# Prints command usage information.
#
printHelp( )
{
	helpText="
  clean [<style> [<target>]]

      Clean all builds, or only builds for a style and optional target.
"
	printf '%s' "$helpText"
}


# Prints command usage to stderr and exits with failure.
#
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

	-*)
		printHelpAndExit
		;;

esac

cleanBuilds "$projDir" "$@" || printHelpAndExit
exit 0
