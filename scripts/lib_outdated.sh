#!/bin/sh

set -eu

[ -n "${__included_lib_outdated_sh:-}" ] && return 0
__included_lib_outdated_sh=1


. lib_assert.sh


# $1 - File or folder to check for being outdated. If it doesn't exist, it
#   is always consider outdated.
# $* - Files or folders to compare it to. If any of these is newer
#   (last mod date), then $1 is outdated. All those files and folder must
#   exist, otherwise $1 is also considered outdated.
#
# Returns 0 if outdated, 1 otherwise.
#
isOutdated( )
(
	target=$1
	shift

	assert "[ -n \"${target:-}\" ]" "isOutdated() missing target"
	assert "[ $# -gt 0 ]" "isOutdated() missing comparison paths"

	[ -e "$target" ] || return 0

	for other in "$@"
	do
		[ -e "$other" ] || return 0
	done

	newer=$( find "$@" -newer "$target" )
	[ -z "$newer" ] && return 1
	return 0
)


# $1 - Dependency file. This file contains one absolute file path per line.
#   If any file listed in the dependency file is newer than the dependency
#   file itself, it is outdated.
#
# Returns 0 if outdated, 1 otherwise.
#
depFileIsOutdated( )
(
	depFile=$1

	assert "[ -n \"${depFile:-}\" ]" "depFileIsOutdated() missing dep file"

	[ -e "$depFile" ] || return 0

	set --

	while IFS= read -r dep || [ -n "$dep" ]
	do
		[ -n "$dep" ] || continue

		set -- "$@" "$dep"
	done < "$depFile"

	[ $# -gt 0 ] || return 1

	isOutdated "$depFile" "$@"
)
