#!/bin/sh

set -eu

[ -n "${__included_lib_build_common_sh:-}" ] && return 0
__included_lib_build_common_sh=1


. lib_error.sh
. lib_quote.sh
. lib_clang.sh
. lib_outdated.sh


# $1 - Variable name.
# $2 - Value.
#
# Sets a variable to the provided value.
#
setVar( )
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
buildFileWithOutput( )
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

	setVar "$_build_out_had_output" "$_build_had_output"

	if [ "$_build_status" -ne 0 ]
	then
		return "$_build_status"
	fi
}


# $1 - Project root directory.
# $2 - Object root directory containing .dep files.
#
# Removes dep files older than the newest style file.
#
purgeOutdatedDepsByStyle( )
(
	_pobs_root=$1
	_pobs_obj_root=$2

	[ -n "$_pobs_root" ] || printErrorAndExit \
		"purgeOutdatedDepsByStyle() missing project root"
	[ -n "$_pobs_obj_root" ] || printErrorAndExit \
		"purgeOutdatedDepsByStyle() missing object root"

	_pobs_style_root=$_pobs_root/styles
	_pobs_newest_style=""

	if [ -d "$_pobs_style_root" ]
	then
		while IFS= read -r _pobs_style_path || [ -n "$_pobs_style_path" ]
		do
			[ -n "$_pobs_style_path" ] || continue
			if [ -z "$_pobs_newest_style" ] \
				|| isOutdated "$_pobs_newest_style" \
					"$_pobs_style_path"
			then
				_pobs_newest_style=$_pobs_style_path
			fi
		done <<EOF
$( find "$_pobs_style_root" -type f )
EOF
	fi

	[ -n "$_pobs_newest_style" ] || return 0
	[ -d "$_pobs_obj_root" ] || return 0

	while IFS= read -r _pobs_dep || [ -n "$_pobs_dep" ]
	do
		[ -n "$_pobs_dep" ] || continue
		if [ -f "$_pobs_dep" ] \
			&& isOutdated "$_pobs_dep" "$_pobs_newest_style"
		then
			rm -f "$_pobs_dep"
		fi
	done <<EOF
$( find "$_pobs_obj_root" -type f -name '*.dep' )
EOF
)


# $1 - Dependency file path.
#
# Ensures a dep file contains at least one path entry.
#
assertDepFileNotEmpty( )
(
	_adp_path=$1

	[ -n "$_adp_path" ] || printErrorAndExit \
		"assertDepFileNotEmpty() missing dep path"
	[ -f "$_adp_path" ] || printErrorAndExit \
		"Dependency file not found: $_adp_path"

	_adp_has_entry=0
	while IFS= read -r _adp_dep || [ -n "$_adp_dep" ]
	do
		[ -n "$_adp_dep" ] || continue
		_adp_has_entry=1
		break
	done < "$_adp_path"

	if [ "$_adp_has_entry" -eq 0 ]
	then
		printErrorAndExit "Dependency file is empty: $_adp_path"
	fi
)


# $1 - Source file path.
# $2 - Dependency file path.
# $3 - Working directory for clang.
# $4 - Quoted clang flags string.
#
# Regenerates the dep file when outdated.
#
updateDepFileIfOutdated( )
(
	_ud_src=$1
	_ud_dep=$2
	_ud_work=$3
	_ud_flags=$4

	[ -n "$_ud_src" ] || printErrorAndExit \
		"updateDepFileIfOutdated() missing source path"
	[ -n "$_ud_dep" ] || printErrorAndExit \
		"updateDepFileIfOutdated() missing dep path"
	[ -n "$_ud_work" ] || printErrorAndExit \
		"updateDepFileIfOutdated() missing work dir"
	[ -n "$_ud_flags" ] || printErrorAndExit \
		"updateDepFileIfOutdated() missing flags"

	if depFileIsOutdated "$_ud_dep"
	then
		generateDepFile "$_ud_src" "$_ud_dep" "$_ud_work" "$_ud_flags"
	fi
)
