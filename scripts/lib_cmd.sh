#!/bin/sh

set -eu

[ -n "${__included_lib_cmd_sh:-}" ] && return 0
__included_lib_cmd_sh=1


# ($1) - Optional script directory path.
#
# Initializes origDir, scriptDir, and projDir, then cd's into scriptDir.
#
initCmdPaths( )
{
	origDir=$( pwd -P )
	scriptDir=${1:-}

	if [ -z "$scriptDir" ]
	then
		scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" \
			&& pwd -P )
	fi

	projDir=$( CDPATH='' cd -- "$scriptDir/.." && pwd -P )

	cd "$scriptDir"
}
