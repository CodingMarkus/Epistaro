#!/bin/sh

set -eu

[ -n "${__included_lib_build_common_sh:-}" ] && return 0
__included_lib_build_common_sh=1


. lib_error.sh
. lib_quote.sh
. lib_clang.sh


# $1 - Variable name.
# $2 - Value.
#
# Sets a variable to the provided value.
#
_setVar( )
{
	_sv_name=$1
	_sv_value=$2

	case "$_sv_name" in
		''|*[!A-Za-z0-9_]*)
			printErrorAndExit "Invalid variable name: $_sv_name"
			;;
	esac

	if [ -n "$_sv_value" ]
	then
		_sv_quoted=$( quote "$_sv_value" )
		eval "$_sv_name=$_sv_quoted"
	else
		eval "$_sv_name="
	fi
}


# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Work directory for the file.
# $5 - Quoted file flags string.
#
# Prepares flags and compiles the file.
#
_buildFile( )
{
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_workDir=$4
	_build_fileFlags=$5

	buildFile "$_build_srcPath" "$_build_objPath" \
		"$_build_workDir" "$_build_fileFlags"
}

# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Work directory for the file.
# $5 - Quoted file flags string.
# $6 - Output variable for compile output flag.
#
# Runs a build and captures clang diagnostics to control compile spacing.
#
_buildFileWithOutput( )
{
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_workDir=$4
	_build_fileFlags=$5
	_build_out_had_output=$6

	_build_tmpPath=$( mktemp "${TMPDIR:-/tmp}/build.XXXXXX" ) \
		|| printErrorAndExit "mktemp failed"

	if _buildFile "$_build_projectRoot" "$_build_srcPath" \
		"$_build_objPath" "$_build_workDir" \
		"$_build_fileFlags" 2>"$_build_tmpPath"
	then
		_build_status=0
	else
		_build_status=$?
	fi

	if [ -s "$_build_tmpPath" ]
	then
		cat "$_build_tmpPath" >&2
		_build_had_output=1
	else
		_build_had_output=0
	fi
	rm -f "$_build_tmpPath"

	_setVar "$_build_out_had_output" "$_build_had_output"

	if [ "$_build_status" -ne 0 ]
	then
		return "$_build_status"
	fi
}
