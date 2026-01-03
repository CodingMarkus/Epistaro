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
_styleEvalCondition( )
{
	_sec_cond=$1
	_sec_path=$2

	_sec_cond=$( _styleTrim "$_sec_cond" )
	case "$_sec_cond" in
		if-set[[:space:]]* )
			_sec_rest=${_sec_cond#if-set}
			_sec_split=$( _styleSplitVarAndRest "$_sec_rest" )
			_sec_oldifs=$IFS
			IFS='
'
			set -- $_sec_split
			IFS=$_sec_oldifs
			_sec_name=${1-}
			_sec_rest=${2-}
			_sec_rest=$( _styleTrim "$_sec_rest" )
			[ -n "$_sec_name" ] || printErrorAndExit \
				"Missing var name in $_sec_path"
			[ -z "$_sec_rest" ] || printErrorAndExit \
				"Unexpected text in $_sec_path: $_sec_cond"
			_styleVarIsSet "$_sec_name" "$_sec_path"
			;;
		if-not-set[[:space:]]* )
			_sec_rest=${_sec_cond#if-not-set}
			_sec_split=$( _styleSplitVarAndRest "$_sec_rest" )
			_sec_oldifs=$IFS
			IFS='
'
			set -- $_sec_split
			IFS=$_sec_oldifs
			_sec_name=${1-}
			_sec_rest=${2-}
			_sec_rest=$( _styleTrim "$_sec_rest" )
			[ -n "$_sec_name" ] || printErrorAndExit \
				"Missing var name in $_sec_path"
			[ -z "$_sec_rest" ] || printErrorAndExit \
				"Unexpected text in $_sec_path: $_sec_cond"
			_styleVarIsSet "$_sec_name" "$_sec_path" && return 1
			return 0
			;;
		if-match[[:space:]]* )
			_sec_rest=${_sec_cond#if-match}
			_sec_split=$( _styleSplitVarAndRest "$_sec_rest" )
			_sec_oldifs=$IFS
			IFS='
'
			set -- $_sec_split
			IFS=$_sec_oldifs
			_sec_name=${1-}
			_sec_rest=${2-}
			[ -n "$_sec_name" ] || printErrorAndExit \
				"Missing var name in $_sec_path"
			_sec_rest=$( _styleTrimLeft "$_sec_rest" )
			case "$_sec_rest" in
				/*/ )
					_sec_pat= ${_sec_rest#/}
					_sec_pat= ${_sec_pat%/}
					;;
				*)
				printErrorAndExit \
					"Invalid match pattern in $_sec_path: $_sec_cond"
					;;
			esac
			if ! _styleVarIsSet "$_sec_name" "$_sec_path"
			then
				return 1
			fi
			_sec_val=$( _styleGetVar "$_sec_name" "$_sec_path" )
			printf '%s' "$_sec_val" | grep -E -q -- "$_sec_pat"
			;;
		if-not-match[[:space:]]* )
			_sec_rest= ${_sec_cond#if-not-match}
			_sec_split=$( _styleSplitVarAndRest "$_sec_rest" )
			_sec_oldifs=$IFS
			IFS='
'
			set -- $_sec_split
			IFS=$_sec_oldifs
			_sec_name=${1-}
			_sec_rest=${2-}
			[ -n "$_sec_name" ] || printErrorAndExit \
				"Missing var name in $_sec_path"
			_sec_rest=$( _styleTrimLeft "$_sec_rest" )
			case "$_sec_rest" in
				/*/ )
					_sec_pat= ${_sec_rest#/}
					_sec_pat= ${_sec_pat%/}
					;;
				*)
				printErrorAndExit \
					"Invalid match pattern in $_sec_path: $_sec_cond"
					;;
			esac
			if ! _styleVarIsSet "$_sec_name" "$_sec_path"
			then
				return 0
			fi
			_sec_val=$( _styleGetVar "$_sec_name" "$_sec_path" )
			if printf '%s' "$_sec_val" | grep -E -q -- "$_sec_pat"
			then
				return 1
			fi
			return 0
			;;
		if-equal[[:space:]]* )
			_sec_rest=${_sec_cond#if-equal}
			_sec_split=$( _styleSplitVarAndRest "$_sec_rest" )
			_sec_oldifs=$IFS
			IFS='
'
			set -- $_sec_split
			IFS=$_sec_oldifs
			_sec_name=${1-}
			_sec_rest=${2-}
			[ -n "$_sec_name" ] || printErrorAndExit \
				"Missing var name in $_sec_path"
			_sec_rest=$( _styleTrimLeft "$_sec_rest" )
			[ -n "$_sec_rest" ] || printErrorAndExit \
				"Missing match value in $_sec_path"
			_sec_exp=$( _styleParseValue "$_sec_rest" "$_sec_path" )
			if ! _styleVarIsSet "$_sec_name" "$_sec_path"
			then
				return 1
			fi
			_sec_val=$( _styleGetVar "$_sec_name" "$_sec_path" )
			[ "$_sec_val" = "$_sec_exp" ]
			;;
		*)
			printErrorAndExit \
				"Unknown include condition in $_sec_path: $_sec_cond"
			;;
	esac
}
