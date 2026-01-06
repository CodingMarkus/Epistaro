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
	_ph_text="
  update

      Update all project configuration and generated files.

  update c[onfig]

      Update build configuration files (like .clangd).
"
	printf '%s' "$_ph_text"
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
_updateConfig( )
{
	_uc_style=$__projDir/styles/_defaults/_common/_ide.cfg
	updateClangd "$__projDir/.clangd" "$_uc_style"
}


# Updates all generated configuration files.
#
_updateAll( )
{
	_updateConfig
}


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	"")
		_updateAll
		exit 0
		;;

	c|config)
		[ "$#" -eq 1 ] || printHelpAndExit
		_updateConfig
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

printHelpAndExit
