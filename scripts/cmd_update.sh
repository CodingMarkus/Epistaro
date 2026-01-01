#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"

. lib_clangd.sh


# Prints command usage information.
#
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


# Prints command usage to stderr and exits with failure.
#
printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


# Updates build configuration files for the project.
#
updateConfig( )
{
	defaultStylePath=$__projDir/styles/_defaults/_default.cfg
	updateClangd "$__projDir/.clangd" "$defaultStylePath"
}


# Updates all generated configuration files.
#
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
