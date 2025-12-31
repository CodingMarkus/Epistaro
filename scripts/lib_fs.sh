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
abs_dir( )
(
	dir=$1

	assert "[ -n \"${dir:-}\" ]" "abs_dir() missing dir"

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
abs_path( )
(
	path=$1

	assert "[ -n \"${path:-}\" ]" "abs_path() missing path"

	case "$path" in
		/*) printf '%s\n' "$path" ;;

		*)
			case "$path" in
				*/*) dir=${path%/*}; base=${path##*/} ;;
				*) dir="."; base=$path ;;
			esac
			dirAbs=$( abs_dir "$dir" ) || return 1
			printf '%s/%s\n' "$dirAbs" "$base"
			;;
	esac
)


# $1 - Path to normalize.
#
# Prints the path without a trailing slash (except for /).
#
strip_trailing_slash( )
{
	path=$1

	assert "[ -n \"${path:-}\" ]" \
		"strip_trailing_slash() missing path"

	case "$path" in
		/) printf '%s\n' "$path" ;;
		*/) printf '%s\n' "${path%/}" ;;
		*) printf '%s\n' "$path" ;;
	esac
}


# $1 - Directory path.
#
# Ensures directory exists.
#
ensure_dir( )
{
	dir=$1

	assert "[ -n \"${dir:-}\" ]" "ensure_dir() missing dir"

	[ -d "$dir" ] || mkdir -p "$dir"
}
