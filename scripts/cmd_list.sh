#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


. lib_list.sh
. lib_paths.sh


# Prints command usage information.
#
printHelp( )
{
	helpText="
  list [-plain] t[argets]

      List available targets.

  list [-plain] s[tyles]

      List available styles.

  list [-plain] te[sts] [<target>]

      List available tests for a target, or all targets.
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
	-plain)
		shift
		plainMode=plain
		;;
	*)
		plainMode=
		;;
esac

case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	t|target|targets)
		[ "$#" -eq 1 ] || printHelpAndExit
		listTargetsAndExit "$projDir" "$plainMode"
		;;

	s|style|styles)
		[ "$#" -eq 1 ] || printHelpAndExit
		listStylesAndExit "$projDir" "$plainMode"
		;;

	te|tests)
		case "$#" in
			1)
				listTestsAndExit "$projDir" "" "$plainMode"
				;;
			2)
				target=$( resolveTargetName "$projDir" "$2" )
				listTestsAndExit "$projDir" "$target" "$plainMode"
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
