#!/bin/sh

set -eu

[ -n "${__included_lib_style_vars_sh:-}" ] && return 0
__included_lib_style_vars_sh=1


. lib_error.sh


# $1 - Raw string to quote.
#
# Prints a single-quoted string safe for eval assignment.
#
_styleQuoteEval( )
{
	printf "'%s'" "$( printf "%s" "$1" | sed "s/'/'\\\\''/g" )"
}


# $1 - Variable name to validate.
# $2 - Style file path for error reporting.
#
# Validates a variable name for read-only use.
#
_styleValidateVarNameRead( )
{
	_svr_name=$1
	_svr_path=$2

	case "$_svr_name" in
		''|[!A-Za-z_]*|*[!A-Za-z0-9_]*)
			printErrorAndExit "Invalid variable name in $_svr_path: $_svr_name"
			;;
	esac
}


# $1 - Variable name to validate.
# $2 - Style file path for error reporting.
#
# Validates a variable name for write operations (reserved names blocked).
#
_styleValidateVarNameWrite( )
{
	_svw_name=$1
	_svw_path=$2

	_styleValidateVarNameRead "$_svw_name" "$_svw_path"
	case "$_svw_name" in
		_*)
			printErrorAndExit \
				"Variables starting with '_' are reserved in "\
"$_svw_path: $_svw_name"
			;;
	esac
}


# $1 - Variable name to check.
#
# Returns success if the name is all caps with digits/underscores.
#
_styleIsAllCapsName( )
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
_styleTrackCapsName( )
{
	_stc_name=$1

	_styleIsAllCapsName "$_stc_name" || return 0

	case "
${__style_caps_vars:-}
" in
		*"
$_stc_name
"*) return 0 ;;
	esac

	if [ -n "${__style_caps_vars:-}" ]
	then
		__style_caps_vars="$__style_caps_vars
$_stc_name"
	else
		__style_caps_vars=$_stc_name
	fi
}


# $1 - Variable name to check.
#
# Returns success if an external script variable is set.
#
_styleExternalVarIsSet( )
{
	_seis_name=$1
	_seis_var="__style_set_$_seis_name"
	eval "_seis_flag=\${$_seis_var+x}"
	[ -n "${_seis_flag:-}" ]
}


# $1 - Variable name to read.
#
# Prints the external script variable value.
#
_styleExternalVarGet( )
{
	_seg_name=$1
	_seg_var="__style_set_$_seg_name"
	eval "printf '%s' \"\${$_seg_var-}\""
}


# $1 - Variable name to set.
# $2 - Variable value.
# $3 - Style file path for error reporting.
#
# Sets a style variable and marks it as present.
#
styleSetVar( )
{
	_ssv_name=$1
	_ssv_value=${2-}
	_ssv_path=$3

	_styleValidateVarNameWrite "$_ssv_name" "$_ssv_path"
	_styleTrackCapsName "$_ssv_name"

	_ssv_var_set="__style_var_set_$_ssv_name"
	_ssv_var_value="__style_var_value_$_ssv_name"

	eval "$_ssv_var_set=1"
	eval "$_ssv_var_value=$(_styleQuoteEval "$_ssv_value")"
}


# $1 - Variable name to unset.
# $2 - Style file path for error reporting.
#
# Unsets a style variable and clears its presence marker.
#
styleUnsetVar( )
{
	_suv_name=$1
	_suv_path=$2

	_styleValidateVarNameWrite "$_suv_name" "$_suv_path"
	_styleTrackCapsName "$_suv_name"

	_suv_var_set="__style_var_set_$_suv_name"
	_suv_var_value="__style_var_value_$_suv_name"

	eval "$_suv_var_set=0"
	eval "unset $_suv_var_value"
}


# $1 - Variable name to check.
# $2 - Style file path for error reporting.
#
# Returns success if the variable has been set.
#
styleVarIsSet( )
{
	_svis_name=$1
	_svis_path=$2

	_styleValidateVarNameRead "$_svis_name" "$_svis_path"

	_svis_var_set="__style_var_set_$_svis_name"
	eval "_svis_flag=\${$_svis_var_set-}"
	case "${_svis_flag:-}" in
		1) return 0 ;;
		0) return 1 ;;
	esac

	_styleExternalVarIsSet "$_svis_name"
}


# $1 - Variable name to read.
# $2 - Style file path for error reporting.
#
# Prints the variable value (empty if unset).
#
styleGetVar( )
{
	_sgv_name=$1
	_sgv_path=$2

	_styleValidateVarNameRead "$_sgv_name" "$_sgv_path"

	_sgv_var_set="__style_var_set_$_sgv_name"
	eval "_sgv_flag=\${$_sgv_var_set-}"
	case "${_sgv_flag:-}" in
		1)
			_sgv_var_value="__style_var_value_$_sgv_name"
			eval "printf '%s' \"\${$_sgv_var_value-}\""
			return 0
			;;
		0)
			printf '%s' ""
			return 0
			;;
	esac

	if _styleExternalVarIsSet "$_sgv_name"
	then
		_styleExternalVarGet "$_sgv_name"
		return 0
	fi

	printf '%s' ""
}


# $1 - Style file path for error reporting.
#
# Prints export/unset commands for tracked all-caps variables.
#
styleExportCapsVars( )
{
	_secv_path=$1

	if [ -z "${__style_caps_vars:-}" ]
	then
		return 0
	fi

	while IFS= read -r _secv_name || [ -n "$_secv_name" ]
	do
		[ -n "$_secv_name" ] || continue
		if styleVarIsSet "$_secv_name" "$_secv_path"
		then
			_secv_value=$( styleGetVar "$_secv_name" "$_secv_path" )
			printf 'export %s=%s\n' "__style_set_$_secv_name" \
				"$(_styleQuoteEval "$_secv_value")"
		else
			printf 'unset %s\n' "__style_set_$_secv_name"
		fi
	done <<EOF
$__style_caps_vars
EOF
}
