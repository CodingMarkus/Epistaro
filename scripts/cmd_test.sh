#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_test.sh


# Prints command usage information.
#
printHelp( )
{
	_ph_text="
  test [[-s[tyle] <style>] ...] [<target>[/suite[/...][/test]] ...]

      Build targets (test style by default), build tests, and run them.
      Repeat -style to test multiple styles in a single run.
      If no target is provided, all targets are tested.
      You can scope to a suite or a specific test using a pseudo path,
      omitting .ut/.it for specific tests.
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


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;
esac

styleName="test"
styleNames=""

while [ "$#" -gt 0 ]
do
	case "$1" in
		--help)
			printHelp
			exit 0
			;;

		-*)
			if isStyleFlag "$1"
			then
				shift
				[ "$#" -gt 0 ] || printHelpAndExit
				styleName=$1
				ensureValidStyleName "$styleName"
				appendStyleName "$styleName"
				shift
				continue
			fi
			printHelpAndExit
			;;

		*)
			break
			;;
	esac
done
if [ -z "$styleNames" ]
then
	styleNames=$styleName
fi

if ! runTests "$__projDir" "$__origDir" "$styleNames" "$@"
then
	exit 1
fi
