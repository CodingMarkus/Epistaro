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


# $1 - Variable name to check.
#
# Returns success if the name is all caps with digits/underscores.
#
_style_is_all_caps_name( )
{
	case "$1" in
		[A-Z][A-Z0-9_]*) return 0 ;;
		*) return 1 ;;
	esac
}


# $1 - Variable name to record.
#
# Tracks all-caps variables for export.
#
_style_track_caps_name( )
{
	name=$1

	_style_is_all_caps_name "$name" || return 0

	case "
${__style_caps_vars:-}
" in
		*"
$name
"*) return 0 ;;
	esac

	if [ -n "${__style_caps_vars:-}" ]
	then
		__style_caps_vars="$__style_caps_vars
$name"
	else
		__style_caps_vars=$name
	fi
}


# $1 - Variable name to check.
#
# Returns success if an external script variable is set.
#
_style_external_var_is_set( )
{
	name=$1
	varName="__style_set_$name"
	eval "flag=\${$varName+x}"
	[ -n "${flag:-}" ]
}


# $1 - Variable name to read.
#
# Prints the external script variable value.
#
_style_external_var_get( )
{
	name=$1
	varName="__style_set_$name"
	eval "printf '%s' \"\${$varName-}\""
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
	_style_track_caps_name "$name"

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
	_style_track_caps_name "$name"

	varSet="__style_var_set_$name"
	varValue="__style_var_value_$name"

	eval "$varSet=0"
	eval "unset $varValue"
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
	case "${flag:-}" in
		1) return 0 ;;
		0) return 1 ;;
	esac

	_style_external_var_is_set "$name"
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

	varSet="__style_var_set_$name"
	eval "flag=\${$varSet-}"
	case "${flag:-}" in
		1)
			varValue="__style_var_value_$name"
			eval "printf '%s' \"\${$varValue-}\""
			return 0
			;;
		0)
			printf '%s' ""
			return 0
			;;
	esac

	if _style_external_var_is_set "$name"
	then
		_style_external_var_get "$name"
		return 0
	fi

	printf '%s' ""
}


# $1 - Style file path for error reporting.
#
# Prints export/unset commands for tracked all-caps variables.
#
_style_export_caps_vars( )
{
	stylePath=$1

	if [ -z "${__style_caps_vars:-}" ]
	then
		return 0
	fi

	while IFS= read -r name || [ -n "$name" ]
	do
		[ -n "$name" ] || continue
		if _style_var_is_set "$name" "$stylePath"
		then
			value=$( _style_get_var "$name" "$stylePath" )
			printf 'export %s=%s\n' "__style_set_$name" \
				"$(_style_quote_eval "$value")"
		else
			printf 'unset %s\n' "__style_set_$name"
		fi
	done <<EOF
$__style_caps_vars
EOF
}
