#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_error.sh


# Prints command usage information.
#
printHelp( )
{
	helpText="
  help [<command>]

      Print help for command.
      Print help for all commands if no command is specified.
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

	"")
		first=1
		for cmdPath in "$__scriptDir"/cmd_*.sh
		do
			[ -e "$cmdPath" ] || continue
			cmdBase=$( basename -- "$cmdPath" )
			[ "$cmdBase" = "cmd_proj.sh" ] && continue
			if [ "$first" -eq 0 ]
			then
				printf '\n'
			fi
			first=0
			sh "$cmdPath" --help || exit 1
		done
		exit 0
		;;

esac

[ "$#" -eq 1 ] || printHelpAndExit

cmdName=$1
cmdPath=$( findCmdScript "$__scriptDir" "$cmdName" ) || \
	printErrorAndExit "Command not found: $cmdName"

sh "$cmdPath" --help
