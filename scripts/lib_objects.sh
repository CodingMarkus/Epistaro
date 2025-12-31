#!/bin/sh

set -eu

[ -n "${__included_lib_objects_sh:-}" ] && return 0
__included_lib_objects_sh=1


. lib_assert.sh
. lib_error.sh
. lib_fs.sh
. lib_quote.sh


# $1 - Working directory for object resolution (absolute or relative).
# $2.. - Object file paths (absolute or relative).
#
# Prints a quoted, space-delimited object argument string for eval.
#
collectObjectArgs( )
(
	workDir=$1
	shift

	assert "[ -n \"${workDir:-}\" ]" \
		"collectObjectArgs() missing work dir"
	assert "[ $# -gt 0 ]" "collectObjectArgs() missing object files"

	case "$workDir" in
		/*) workDirAbs=$workDir ;;

		*)
			workDirAbs=$( abs_dir "$workDir" ) \
				|| printErrorAndExit "Work dir not found: $workDir"
			;;
	esac
	workDirAbs=$( strip_trailing_slash "$workDirAbs" )

	objArgs=""
	for objPath in "$@"
	do
		[ -n "$objPath" ] || continue
		case "$objPath" in
			/*) objAbs=$objPath ;;
			*) objAbs=$workDirAbs/$objPath ;;
		esac
		[ -f "$objAbs" ] \
			|| printErrorAndExit "Object file not found: $objAbs"
		quotedObj=$( quote "$objAbs" )
		if [ -z "$objArgs" ]
		then
			objArgs=$quotedObj
		else
			objArgs="$objArgs $quotedObj"
		fi
	done

	printf '%s\n' "$objArgs"
)
