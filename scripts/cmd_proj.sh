#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_error.sh


cmdName=${1:-}
if [ -z "$cmdName" ]
then
	cmdName=help
elif [ "$cmdName" = "--help" ] && [ "$#" -eq 1 ]
then
	cmdName=help
	shift
else
	shift
fi

cmdPath=$( findCmdScript "$__scriptDir" "$cmdName" ) || \
	printErrorAndExit "Command not found: $cmdName"

appendNote=0
if [ "$cmdName" = "help" ] && [ "$#" -eq 0 ]
then
	appendNote=1
fi

sh "$cmdPath" "$@"
status=$?
if [ "$status" -ne 0 ]
then
	exit "$status"
fi

if [ "$appendNote" -eq 1 ]
then
	printf '\n\n  %s%s\n' \
		'Commands can be matched by partial names (up to a single ' \
		'letter).'
fi

exit 0
