#!/bin/sh

set -eu

[ -n "${__included_lib_style_include_sh:-}" ] && return 0
__included_lib_style_include_sh=1


. lib_error.sh
. lib_style_parse.sh
. lib_style_vars.sh


# $1 - Condition expression.
# $2 - Style file path for error reporting.
#
# Evaluates an include condition.
#
_style_eval_condition( )
{
	cond=$1
	stylePath=$2

	cond=$( _style_trim "$cond" )
	case "$cond" in
		if-set[[:space:]]* )
			rest=${cond#if-set}
			split=$( _style_split_var_and_rest "$rest" )
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			varName=${1-}
			rest=${2-}
			rest=$( _style_trim "$rest" )
			[ -n "$varName" ] || \
				printErrorAndExit "Missing var name in $stylePath"
			[ -z "$rest" ] || \
				printErrorAndExit "Unexpected text in $stylePath: $cond"
			_style_var_is_set "$varName" "$stylePath"
			;;
		if-not-set[[:space:]]* )
			rest=${cond#if-not-set}
			split=$( _style_split_var_and_rest "$rest" )
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			varName=${1-}
			rest=${2-}
			rest=$( _style_trim "$rest" )
			[ -n "$varName" ] || \
				printErrorAndExit "Missing var name in $stylePath"
			[ -z "$rest" ] || \
				printErrorAndExit "Unexpected text in $stylePath: $cond"
			_style_var_is_set "$varName" "$stylePath" && return 1
			return 0
			;;
		if-match[[:space:]]* )
			rest=${cond#if-match}
			split=$( _style_split_var_and_rest "$rest" )
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			varName=${1-}
			rest=${2-}
			[ -n "$varName" ] || \
				printErrorAndExit "Missing var name in $stylePath"
			rest=$( _style_trim_left "$rest" )
			case "$rest" in
				/*/ )
					pattern=${rest#/}
					pattern=${pattern%/}
					;;
				*)
					printErrorAndExit \
						"Invalid match pattern in $stylePath: $cond"
					;;
			esac
			if ! _style_var_is_set "$varName" "$stylePath"
			then
				return 1
			fi
			value=$( _style_get_var "$varName" "$stylePath" )
			printf '%s' "$value" | grep -E -q -- "$pattern"
			;;
		if-not-match[[:space:]]* )
			rest=${cond#if-not-match}
			split=$( _style_split_var_and_rest "$rest" )
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			varName=${1-}
			rest=${2-}
			[ -n "$varName" ] || \
				printErrorAndExit "Missing var name in $stylePath"
			rest=$( _style_trim_left "$rest" )
			case "$rest" in
				/*/ )
					pattern=${rest#/}
					pattern=${pattern%/}
					;;
				*)
					printErrorAndExit \
						"Invalid match pattern in $stylePath: $cond"
					;;
			esac
			if ! _style_var_is_set "$varName" "$stylePath"
			then
				return 0
			fi
			value=$( _style_get_var "$varName" "$stylePath" )
			if printf '%s' "$value" | grep -E -q -- "$pattern"
			then
				return 1
			fi
			return 0
			;;
		if-equal[[:space:]]* )
			rest=${cond#if-equal}
			split=$( _style_split_var_and_rest "$rest" )
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			varName=${1-}
			rest=${2-}
			[ -n "$varName" ] || \
				printErrorAndExit "Missing var name in $stylePath"
			rest=$( _style_trim_left "$rest" )
			[ -n "$rest" ] || \
				printErrorAndExit "Missing match value in $stylePath"
			expected=$( _style_parse_value "$rest" "$stylePath" )
			if ! _style_var_is_set "$varName" "$stylePath"
			then
				return 1
			fi
			value=$( _style_get_var "$varName" "$stylePath" )
			[ "$value" = "$expected" ]
			;;
		*)
			printErrorAndExit "Unknown include condition in $stylePath: $cond"
			;;
	esac
}
