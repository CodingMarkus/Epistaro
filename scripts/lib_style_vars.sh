#!/bin/sh

set -eu

[ -n "${__included_lib_style_vars_sh:-}" ] && return 0
__included_lib_style_vars_sh=1


. lib_error.sh


# $1 - Raw string to quote.
#
# Prints a single-quoted string safe for eval assignment.
#
_style_quote_eval( )
{
	printf "'%s'" "$( printf "%s" "$1" | sed "s/'/'\\\\''/g" )"
}


# $1 - Variable name to validate.
# $2 - Style file path for error reporting.
#
# Validates a variable name for read-only use.
#
_style_validate_var_name_read( )
{
	name=$1
	stylePath=$2

	case "$name" in
		''|[!A-Za-z_]*|*[!A-Za-z0-9_]*)
			printErrorAndExit "Invalid variable name in $stylePath: $name"
			;;
	esac
}


# $1 - Variable name to validate.
# $2 - Style file path for error reporting.
#
# Validates a variable name for write operations (reserved names blocked).
#
_style_validate_var_name_write( )
{
	name=$1
	stylePath=$2

	_style_validate_var_name_read "$name" "$stylePath"
	case "$name" in
		_*)
			printErrorAndExit \
				"Variables starting with '_' are reserved in $stylePath: $name"
			;;
	esac
}


# $1 - Variable name to set.
# $2 - Variable value.
# $3 - Style file path for error reporting.
#
# Sets a style variable and marks it as present.
#
_style_set_var( )
{
	name=$1
	value=${2-}
	stylePath=$3

	_style_validate_var_name_write "$name" "$stylePath"

	varSet="__style_var_set_$name"
	varValue="__style_var_value_$name"

	eval "$varSet=1"
	eval "$varValue=$(_style_quote_eval "$value")"
}


# $1 - Variable name to unset.
# $2 - Style file path for error reporting.
#
# Unsets a style variable and clears its presence marker.
#
_style_unset_var( )
{
	name=$1
	stylePath=$2

	_style_validate_var_name_write "$name" "$stylePath"

	varSet="__style_var_set_$name"
	varValue="__style_var_value_$name"

	eval "unset $varSet $varValue"
}


# $1 - Variable name to check.
# $2 - Style file path for error reporting.
#
# Returns success if the variable has been set.
#
_style_var_is_set( )
{
	name=$1
	stylePath=$2

	_style_validate_var_name_read "$name" "$stylePath"

	varSet="__style_var_set_$name"
	eval "flag=\${$varSet-}"
	[ -n "${flag:-}" ]
}


# $1 - Variable name to read.
# $2 - Style file path for error reporting.
#
# Prints the variable value (empty if unset).
#
_style_get_var( )
{
	name=$1
	stylePath=$2

	_style_validate_var_name_read "$name" "$stylePath"

	varValue="__style_var_value_$name"
	eval "printf '%s' \"\${$varValue-}\""
}
