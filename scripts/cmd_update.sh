#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"

. lib_clangd.sh


printHelp( )
{
	helpText="
  update

      Update all project configuration and generated files.

  update c[onfig]

      Update build configuration files (like .clangd).
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
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	"")
		updateAll
		exit 0
		;;

	c|config)
		[ "$#" -eq 1 ] || printHelpAndExit
		updateConfig
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

printHelpAndExit
