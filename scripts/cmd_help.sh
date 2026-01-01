#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"

. lib_error.sh


printHelp( )
{
	helpText="
  help [<command>]

      Print help for command.
      Print help for all commands if no command is specified.
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

	-*)
		printHelpAndExit
		;;

	"")
		for cmdPath in "$scriptDir"/cmd_*.sh
		do
			[ -e "$cmdPath" ] || continue
			cmdBase=$( basename -- "$cmdPath" )
			[ "$cmdBase" = "cmd_proj.sh" ] && continue
			sh "$cmdPath" --help || exit 1
		done
		exit 0
		;;

esac

[ "$#" -eq 1 ] || printHelpAndExit

cmdName=$1
cmdPath=$( findCmdScript "$scriptDir" "$cmdName" ) || \
	printErrorAndExit "Command not found: $cmdName"

sh "$cmdPath" --help
