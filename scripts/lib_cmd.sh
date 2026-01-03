#!/bin/sh

set -eu

[ -n "${__included_lib_cmd_sh:-}" ] && return 0
__included_lib_cmd_sh=1


# $1 - Script directory path.
#
# Initializes __origDir, __scriptDir, and __projDir.
# Then cd's into __scriptDir.
#
initCmdPaths( )
{
	# shellcheck disable=SC2034
	__origDir=$( pwd -P )
	__scriptDir=${1:-}

	[ -n "$__scriptDir" ] || {
		printf '%s\n' "Error: initCmdPaths() missing script dir" >&2
		exit 1
	}

	# shellcheck disable=SC2034
	__projDir=$( CDPATH='' cd -- "$__scriptDir/.." && pwd -P )

	cd "$__scriptDir"
}


# $1 - Script directory path.
# $2 - Command name.
#
# Finds the script for a command name or prefix, excluding cmd_proj.sh.
#
findCmdScript( )
(
	cmdDir=${1:-}
	cmdName=${2:-}

	[ -n "$cmdDir" ] || return 1
	[ -n "$cmdName" ] || return 1

	case "$cmdName" in
		*/*) return 1 ;;
	esac

	exactPath="$cmdDir/cmd_${cmdName}.sh"
	if [ -f "$exactPath" ] \
		&& [ "$( basename -- "$exactPath" )" != "cmd_proj.sh" ]
	then
		printf '%s\n' "$exactPath"
		return 0
	fi

	for cmdPath in "$cmdDir"/cmd_"$cmdName"*.sh
	do
		[ -e "$cmdPath" ] || continue
		cmdBase=$( basename -- "$cmdPath" )
		[ "$cmdBase" = "cmd_proj.sh" ] && continue
		printf '%s\n' "$cmdPath"
		return 0
	done

	return 1
)
