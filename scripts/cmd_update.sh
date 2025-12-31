#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
projDir=$( CDPATH='' cd -- "$scriptDir/.." && pwd -P )

cd "$scriptDir"

. lib_clangd.sh


printHelp( )
{
	helpText="
  update

      Update all project configuration and generated files.


  update config|cfg

      Update build configuration files (like .clangd).


  update -h[elp]

      Show this help screen.
"
	printf '%s' "$helpText"
}


printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


updateConfig( )
{
	defaultStylePath=$projDir/styles/_defaults/_default.cfg
	updateClangd "$projDir/.clangd" "$defaultStylePath"
}


updateAll( )
{
	updateConfig
}


case "${1:-}" in
	-help|-h)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	"")
		updateAll
		exit 0
		;;

	config|cfg)
		[ "$#" -eq 1 ] || printHelpAndExit
		updateConfig
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

printHelpAndExit
