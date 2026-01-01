#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


. lib_list.sh


printHelp( )
{
	helpText="
  list t[argets] [plain]

      List available targets.

  list s[tyles] [plain]

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
		case "${2:-}" in
			"")
				[ "$#" -eq 1 ] || printHelpAndExit
				listTargetsAndExit "$projDir"
				;;
			plain)
				[ "$#" -eq 2 ] || printHelpAndExit
				listTargetsAndExit "$projDir" plain
				;;
			*)
				printHelpAndExit
				;;
		esac
		;;

	s|style|styles)
		case "${2:-}" in
			"")
				[ "$#" -eq 1 ] || printHelpAndExit
				listStylesAndExit "$projDir"
				;;
			plain)
				[ "$#" -eq 2 ] || printHelpAndExit
				listStylesAndExit "$projDir" plain
				;;
			*)
				printHelpAndExit
				;;
		esac
		;;

	-*)
		printHelpAndExit
		;;

	"")
		printHelpAndExit
		;;

esac

printHelpAndExit
