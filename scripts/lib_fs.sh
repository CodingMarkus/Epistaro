#!/bin/sh

set -eu

[ -n "${__included_lib_fs_sh:-}" ] && return 0
__included_lib_fs_sh=1


. lib_assert.sh


# $1 - Directory path.
#
# Prints absolute path for the directory.
# Returns non-zero if the directory cannot be resolved.
#
absDir( )
(
	dir=$1

	assert "[ -n \"${dir:-}\" ]" "absDir() missing dir"

	case "$dir" in
		/*) printf '%s\n' "$dir" ;;

		*)
			CDPATH='' cd -- "$dir" 2>/dev/null && pwd -P
			;;
	esac
)


# $1 - File path.
#
# Prints absolute path for the file.
# Returns non-zero if the path cannot be resolved.
#
absPath( )
(
	path=$1

	assert "[ -n \"${path:-}\" ]" "absPath() missing path"

	case "$path" in
		/*) printf '%s\n' "$path" ;;

		*)
			case "$path" in
				*/*) dir=${path%/*}; base=${path##*/} ;;
				*) dir="."; base=$path ;;
			esac
			dirAbs=$( absDir "$dir" ) || return 1
			printf '%s/%s\n' "$dirAbs" "$base"
			;;
	esac
)


# $1 - Path to normalize.
#
# Prints the path without a trailing slash (except for /).
#
stripTrailingSlash( )
{
	_sts_path=$1

	assert "[ -n \"${_sts_path:-}\" ]" \
		"stripTrailingSlash() missing path"

	case "$_sts_path" in
		/) printf '%s\n' "$_sts_path" ;;
		*/) printf '%s\n' "${_sts_path%/}" ;;
		*) printf '%s\n' "$_sts_path" ;;
	esac
}


# $1 - Directory path.
#
# Ensures directory exists.
#
ensureDir( )
{
	_ed_dir=$1

	assert "[ -n \"${_ed_dir:-}\" ]" "ensureDir() missing dir"

	[ -d "$_ed_dir" ] || mkdir -p "$_ed_dir"
}
