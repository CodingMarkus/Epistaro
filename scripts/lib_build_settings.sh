#!/bin/sh

set -eu

[ -n "${__included_lib_build_settings_sh:-}" ] && return 0
__included_lib_build_settings_sh=1


. lib_assert.sh
. lib_error.sh
. lib_build_common.sh
. lib_fs.sh
. lib_platform.sh
. lib_print.sh
. lib_quote.sh
. lib_sanitize.sh
. lib_style.sh


# $1 - Build style file path.
#
# Prints expanded build styles
#
expandStyle( )
{
	_exp_depth=${__style_parse_depth:-0}
	_exp_depth=$((_exp_depth + 1))
	__style_parse_depth=$_exp_depth

	eval "__style_saved_stylePath_$_exp_depth=\${_exp_path-}"
	eval "__style_saved_styleDir_$_exp_depth=\${_exp_dir-}"
	eval "__style_saved_stylePathAbs_$_exp_depth=\${_exp_path_abs-}"
	eval "__style_saved_styleDirAbs_$_exp_depth=\${_exp_dir_abs-}"
eval \
	"__style_saved_includeStack_$_exp_depth=\${__style_include_stack-}"

	_exp_path=$1

	assert "[ -n \"${_exp_path:-}\" ]" "expandStyle() missing style path"
	assert "[ -e \"$_exp_path\" ]" "style file not found: $_exp_path"

	if [ "$_exp_depth" -eq 1 ]
	then
		__style_caps_vars=""
	fi

	case "$_exp_path" in
		*/*) _exp_dir=${_exp_path%/*} ;;
		*) _exp_dir="." ;;
	esac
	case "$_exp_path" in
		/*) _exp_path_abs=$_exp_path ;;

		*)
			_exp_path_abs=$( absPath "$_exp_path" ) \
				|| printErrorAndExit \
					"Style dir not found: $_exp_dir"
			;;
	esac
	_exp_dir_abs=${_exp_path_abs%/*}
	[ -n "$_exp_dir_abs" ] || _exp_dir_abs=/

	_exp_stack=${__style_include_stack:-}
	case ":$_exp_stack:" in
		*":$_exp_path_abs:"*)
			printErrorAndExit \
				"Style include cycle detected: $_exp_path_abs"
			;;
	esac
	if [ -n "$_exp_stack" ]
	then
		__style_include_stack="$_exp_stack:$_exp_path_abs"
	else
		__style_include_stack=$_exp_path_abs
	fi

	_exp_path_for_messages=$_exp_path

	while IFS= read -r _exp_line || [ -n "$_exp_line" ]
	do
		_exp_trim=$( printf '%s' "$_exp_line" \
			| sed 's/^[[:space:]]*//' )
		[ -z "$_exp_trim" ] && continue

		case "$_exp_trim" in
			\#*) continue ;;

			\$set[[:space:]]* )
				_exp_set_line=${_exp_trim#"\$set"}
				_exp_split=$( styleSplitVarAndRest \
					"$_exp_set_line" )
				case "$_exp_split" in
					*"
"*)
						_exp_name=${_exp_split%%"
"*}
						_exp_rest=${_exp_split#*"
"}
						;;
					*)
						_exp_name=$_exp_split
						_exp_rest=
						;;
				esac
				[ -n "$_exp_name" ] || \
					printErrorAndExit \
						"\$set missing name in "\
"$_exp_path_for_messages"
				_exp_value=$( styleParseValue "$_exp_rest" \
					"$_exp_path_for_messages" )
				styleSetVar "$_exp_name" "$_exp_value" \
					"$_exp_path_for_messages"
				;;
			\$unset[[:space:]]* )
				_exp_unset_line=${_exp_trim#"\$unset"}
				_exp_split=$( styleSplitVarAndRest \
					"$_exp_unset_line" )
				case "$_exp_split" in
					*"
"*)
						_exp_name=${_exp_split%%"
"*}
						_exp_rest=${_exp_split#*"
"}
						;;
					*)
						_exp_name=$_exp_split
						_exp_rest=
						;;
				esac
				[ -n "$_exp_name" ] || printErrorAndExit \
					"\$unset missing name in "\
"$_exp_path_for_messages"
				_exp_rest=$( styleTrim "$_exp_rest" )
				[ -z "$_exp_rest" ] || printErrorAndExit \
					"Unexpected text in "\
"$_exp_path_for_messages: $_exp_trim"
				styleUnsetVar "$_exp_name" \
					"$_exp_path_for_messages"
				;;
			\$include\?[[:space:]]*|\
			\$include\?\(*|\
			\$include[[:space:]]*|\
			\$include\(* )
				_exp_inc_opt=0
				case "$_exp_trim" in
						\$include\?*)
							_exp_inc_opt=1
							_exp_inc_line=$_exp_trim
							_exp_inc_line=\
${_exp_inc_line#"\$include?"}
							;;
						*)
							_exp_inc_line=$_exp_trim
							_exp_inc_line=\
${_exp_inc_line#"\$include"}
							;;
					esac
				_exp_inc_dir="\$include"
				if [ "$_exp_inc_opt" -eq 1 ]
				then
					_exp_inc_dir="\$include?"
				fi
				_exp_inc_line=$( styleTrimLeft \
					"$_exp_inc_line" )
				_exp_inc_ok=1
				case "$_exp_inc_line" in
						\(* )
							_exp_cond_block=$_exp_inc_line
							_exp_cond_block=\
${_exp_cond_block#\(}
							case "$_exp_cond_block" in
								*\)* )
									_exp_cond=\
$_exp_cond_block
									_exp_cond=\
${_exp_cond%%\)*}
									_exp_after=\
$_exp_cond_block
									_exp_after=\
${_exp_after#"$_exp_cond"}
									_exp_after=\
${_exp_after#\)}
									_exp_inc_line=$( \
										styleTrimLeft "$_exp_after" )
									;;
								*)
									printErrorAndExit \
										"Missing ')' in include "\
"condition in $_exp_path_for_messages"
									;;
							esac
							if styleEvalCondition \
								"$_exp_cond" \
								"$_exp_path_for_messages"
							then
								_exp_inc_ok=1
							else
							_exp_inc_ok=0
						fi
						;;
				esac
				_exp_inc_name=$( styleTrim "$_exp_inc_line" )
					if [ -z "$_exp_inc_name" ]
					then
						printErrorAndExit \
							"$_exp_inc_dir missing name in "\
"$_exp_path_for_messages"
					fi
				if [ "$_exp_inc_ok" -eq 0 ]
				then
					continue
				fi
				case "$_exp_inc_name" in
					/*) _exp_inc_path=$_exp_inc_name ;;
					*)
						_exp_inc_path=\
"$_exp_dir_abs/$_exp_inc_name"
						;;
				esac
				if [ -e "$_exp_inc_path" ]
				then
					expandStyle "$_exp_inc_path"
				else
					if [ "$_exp_inc_opt" -eq 1 ]
					then
						:
					else
							printErrorAndExit \
								"\$include style "\
"not found: $_exp_inc_name"
					fi
				fi
				;;

			\$*)
				printErrorAndExit \
					"Unknown directive in "\
"$_exp_path_for_messages: $_exp_trim"
				;;

			*)
				if [ "${__style_emit_settings:-1}" != "0" ]
				then
					printf '%s\n' "$_exp_trim"
				fi
				;;
		esac
	done < "$_exp_path"

	if [ "$_exp_depth" -eq 1 ] && [ -n "${__style_emit_exports:-}" ]
	then
		styleExportCapsVars "$_exp_path"
	fi

	eval "_exp_path=\${__style_saved_stylePath_$_exp_depth-}"
	eval "_exp_dir=\${__style_saved_styleDir_$_exp_depth-}"
	eval "_exp_path_abs=\${__style_saved_stylePathAbs_$_exp_depth-}"
	eval "_exp_dir_abs=\${__style_saved_styleDirAbs_$_exp_depth-}"
eval \
	"__style_include_stack=\${__style_saved_includeStack_$_exp_depth-}"
eval "unset __style_saved_stylePath_$_exp_depth"
eval "unset __style_saved_styleDir_$_exp_depth"
eval "unset __style_saved_stylePathAbs_$_exp_depth"
eval "unset __style_saved_styleDirAbs_$_exp_depth"
eval "unset __style_saved_includeStack_$_exp_depth"

	_exp_depth=$((_exp_depth - 1))
	if [ "$_exp_depth" -gt 0 ]
	then
		__style_parse_depth=$_exp_depth
	else
		unset __style_parse_depth
	fi
}


# Returns success if build debug output is enabled.
#
buildDebugEnabled( )
{
	case "${BUILD_DEBUG:-}" in
		""|0) return 1 ;;
		*) return 0 ;;
	esac
}


# $1 - Command name.
# $2.. - Command arguments.
#
# Prints the full command line when build debug is enabled.
#
buildDebugPrintCommand( )
{
	_bdp_cmd=$1
	shift

	buildDebugEnabled || return 0

	_bdp_line=$( quote "$_bdp_cmd" )
	for _bdp_arg in "$@"
	do
		_bdp_line="$_bdp_line $( quote "$_bdp_arg" )"
	done
	printf '%s\n' "$_bdp_line" >&2
}


# $1 - Source directory to check for compile_flags.txt.
# $2 - Project root directory.
#
# Prints the path to the nearest compile_flags.txt, searching parent
# directories up to the project root.
#
_findCompileFlags( )
(
	srcDir=$1
	projectRoot=$2

	assert "[ -n \"${srcDir:-}\" ]" "_findCompileFlags() missing source dir"
	assert "[ -n \"${projectRoot:-}\" ]" \
		"_findCompileFlags() missing project root dir"

	case "$projectRoot" in
		/*) ;;

		*)
			projectRoot=$( absDir "$projectRoot" ) || projectRoot=/
			;;
	esac

	case "$srcDir" in
		/*) searchDir=$srcDir ;;

		*)
			searchDir=$( absDir "$srcDir" ) || return 0
			;;
	esac

	case "$searchDir" in
		"$projectRoot"/*|"$projectRoot") ;;
		*) projectRoot=/ ;;
	esac

	while :
	do
		flagsPath=$searchDir/compile_flags.txt
		if [ -f "$flagsPath" ]
		then
			printf '%s\n' "$flagsPath"
			return 0
		fi

		if [ "$searchDir" = "$projectRoot" ] || [ "$searchDir" = "/" ]
		then
			return 0
		fi

		parentDir=${searchDir%/*}
		[ -n "$parentDir" ] || return 0
		searchDir=$parentDir
	done
)


# $1 - compile_flags.txt path.
#
# Prints compile flags (one per line). Format matches expandStyle() parsing
# rules but without directives.
#
_readCompileFlags( )
(
	flagsPath=$1

	assert "[ -n \"${flagsPath:-}\" ]" \
		"_readCompileFlags() missing flags path"
	assert "[ -f \"$flagsPath\" ]" \
		"compile_flags.txt not found: $flagsPath"

	while IFS= read -r line || [ -n "$line" ]
	do
		trimmed=$( printf '%s' "$line" | sed 's/^[[:space:]]*//' )
		[ -z "$trimmed" ] && continue

		case "$trimmed" in
			\#*) continue ;;
		esac

		printf '%s\n' "$trimmed"
	done < "$flagsPath"
)


# $1 - Project root directory.
# $2 - Source directory for the file.
# $3 - Quoted build settings string.
# $4 - Build sanitizer settings list.
# $5 - Target sanitizer settings list.
# $6 - Target sanitizer paths list.
# $7 - Output variable for work dir.
# $8 - Output variable for file flags.
# $9 - Output variable for target sanitizer settings.
# $10 - Output variable for target sanitizer paths.
#
# Sets outputs for the file build step and updated sanitizer state.
#
prepareFlags( )
{
	_pf_project_root=$1
	_pf_src_dir=$2
	_pf_build_settings=$3
	_pf_build_sanitize=$4
	_pf_target_sanitize=$5
	_pf_target_paths=$6
	_pf_out_work=$7
	_pf_out_flags=$8
	_pf_out_target=$9
	shift 9
	_pf_out_paths=$1

	# Find any compile_flags.txt and read it
	_pf_flags_path=$( _findCompileFlags "$_pf_src_dir" "$_pf_project_root" )
	_pf_flags_dir=""
	_pf_flags_dir_flags=""
	_pf_flags_sanitize_settings=""

	if [ "${__cached_flags_path:-}" = "$_pf_flags_path" ]
	then
		_pf_flags_dir=${__cached_flags_dir:-}
		_pf_flags_dir_flags=${__cached_flags_dirFlags:-}
		_pf_flags_sanitize_settings=${__cached_sanitizeSettings:-}
	else
		_pf_flags_dir_settings=""
		if [ -n "$_pf_flags_path" ]
		then
			case "$_pf_flags_path" in
				*/*) _pf_flags_dir=${_pf_flags_path%/*} ;;
				*) _pf_flags_dir="." ;;
			esac
			_pf_flags_dir_settings=$( _readCompileFlags \
				"$_pf_flags_path" )
		fi
		_pf_flags_sanitize_settings=$( sanitizeSettingsFromList \
			"$_pf_flags_dir_settings" )
		_pf_flags_dir_flags=$( quoteSettings \
			"$_pf_flags_dir_settings" )
		__cached_flags_path=$_pf_flags_path
		__cached_flags_dir=$_pf_flags_dir
		__cached_flags_dirFlags=$_pf_flags_dir_flags
		__cached_sanitizeSettings=$_pf_flags_sanitize_settings
	fi

	_pf_target_sanitize_result=$_pf_target_sanitize
	_pf_target_paths_result=$_pf_target_paths
	if [ -n "$_pf_flags_sanitize_settings" ]
	then
		_pf_apply_sanitize=1
		if [ -n "$_pf_flags_path" ]
		then
			case "
$_pf_target_paths_result
" in
				*"
$_pf_flags_path
"*) _pf_apply_sanitize= ;;
			esac
		fi
		if [ -n "$_pf_apply_sanitize" ]
		then
			while IFS= read -r _pf_sanitize_flag \
				|| [ -n "$_pf_sanitize_flag" ]
			do
				[ -n "$_pf_sanitize_flag" ] || continue
				_pf_target_sanitize_result=$(
					addTargetSanitizeSetting \
						"$_pf_build_sanitize" \
						"$_pf_target_sanitize_result" \
						"$_pf_sanitize_flag"
				)
			done <<EOF
$_pf_flags_sanitize_settings
EOF
			if [ -n "$_pf_flags_path" ]
			then
				if [ -n "$_pf_target_paths_result" ]
				then
					_pf_target_paths_result=\
"$_pf_target_paths_result
$_pf_flags_path"
				else
					_pf_target_paths_result=$_pf_flags_path
				fi
			fi
		fi
	fi
	if [ -n "$_pf_flags_dir" ]
	then
		_pf_work_dir=$_pf_flags_dir
	else
		_pf_work_dir=$_pf_src_dir
	fi

	# Create final build flags for the file to build
	_pf_file_flags=$( appendQuotedSettings \
		"$_pf_build_settings" "$_pf_flags_dir_flags" )

	if [ -z "$_pf_file_flags" ]
	then
		_pf_file_flags="--"
	fi

	setVar "$_pf_out_work" "$_pf_work_dir"
	setVar "$_pf_out_flags" "$_pf_file_flags"
	setVar "$_pf_out_target" "$_pf_target_sanitize_result"
	setVar "$_pf_out_paths" "$_pf_target_paths_result"
}


# Prints hardcoded build settings (one per line).
#
_hardcodedBuildSettings( )
{
	printf '%s\n' "-flto=thin"
}


# $1 - Quoted build settings string.
#
# Prints quoted build flags that should propagate to link.
#
_linkBuildFlagsFromSettings( )
(
	_lbfs_settings=$1

	[ -n "$_lbfs_settings" ] || return 0

	_lbfs_output=""
	_lbfs_expect_arg=""

	eval "set -- $_lbfs_settings"
	while [ "$#" -gt 0 ]
	do
		_lbfs_flag=$1
		shift

		if [ -n "$_lbfs_expect_arg" ]
		then
			_lbfs_output=$( appendQuotedSettings \
				"$_lbfs_output" "$( quote "$_lbfs_flag" )" )
			_lbfs_expect_arg=""
			continue
		fi

		case "$_lbfs_flag" in
			-target|-mcpu|-mfpu|-mfloat-abi|-march|-mtune|-mabi|\
			-isysroot|-stdlib|-rtlib|-unwindlib|-Xlinker)
				_lbfs_output=$( appendQuotedSettings \
					"$_lbfs_output" "$( quote "$_lbfs_flag" )" )
				_lbfs_expect_arg=1
				;;
			-target=*|-mcpu=*|-mfpu=*|-mfloat-abi=*|-march=*|\
			-mtune=*|-mabi=*|-isysroot=*|-stdlib=*|-rtlib=*|\
			-unwindlib=*)
				_lbfs_output=$( appendQuotedSettings \
					"$_lbfs_output" "$( quote "$_lbfs_flag" )" )
				;;
			-g*|-O*|-flto*|-m32|-m64|-f*|-Wl,*)
				case "$_lbfs_flag" in
					-fsanitize|-fsanitize=*) ;;
					*)
						_lbfs_output=$( appendQuotedSettings \
							"$_lbfs_output" \
							"$( quote "$_lbfs_flag" )" )
						;;
				esac
				;;
		esac
	done

	if [ -n "$_lbfs_output" ]
	then
		printf '%s' "$_lbfs_output"
	fi
)


# $1 - Quoted build settings string.
#
# Prints quoted build flags that should propagate to link.
#
linkBuildFlagsFromSettings( )
(
	_lbf_settings=$1

	_linkBuildFlagsFromSettings "$_lbf_settings"
)


# $1 - Quoted build settings string.
#
# Prints quoted link flags with LTO options removed.
#
linkBuildFlagsWithoutLtoFromSettings( )
(
	_lbfl_settings=$1
	_lbfl_flags=$( _linkBuildFlagsFromSettings "$_lbfl_settings" )

	[ -n "$_lbfl_flags" ] || return 0

	_lbfl_output=""
	eval "set -- $_lbfl_flags"
	while [ "$#" -gt 0 ]
	do
		case "$1" in
			-flto|-flto=*) ;;
			*)
				_lbfl_output=$( appendQuotedSettings \
					"$_lbfl_output" "$( quote "$1" )" )
				;;
		esac
		shift
	done

	if [ -n "$_lbfl_output" ]
	then
		printf '%s' "$_lbfl_output"
	fi
)


# Prints color diagnostic flags when supported.
#
_colorBuildSettings( )
{
	if supportsColorDiagnostics
	then
		printf '%s\n' "-fcolor-diagnostics"
	fi
}


# $1 - Build style file path.
#
# Prints the quoted build settings string for the style.
#
_buildSettingsForStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" \
		"_buildSettingsForStyle() missing path"

	styleSettings=$( expandStyle "$stylePath" )

	quoteSettings "$styleSettings"
)


# $1 - Build style file path.
#
# Prints export/unset commands for all-caps style variables.
#
_styleExportsForStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" \
		"_styleExportsForStyle() missing path"

	__style_emit_settings=0
	__style_emit_exports=1
	__style_caps_vars=""

	expandStyle "$stylePath"
)


# $1 - Build style file path.
#
# Updates exported __style_set_* vars for all-caps style variables.
#
syncStyleSetVars( )
{
	_ssv_path=$1

	assert "[ -n \"${_ssv_path:-}\" ]" \
		"syncStyleSetVars() missing path"

	_ssv_lines=$( _styleExportsForStyle "$_ssv_path" )
	[ -n "$_ssv_lines" ] || return 0

	while IFS= read -r _ssv_line || [ -n "$_ssv_line" ]
	do
		[ -n "$_ssv_line" ] || continue
		eval "$_ssv_line"
	done <<EOF
$_ssv_lines
EOF
}


# $1 - Build style file path.
#
# ($2) - Extra settings string containing one entry per line.
# Prints the quoted build settings string for the style plus active
# terminal-driven settings and any extra settings.
#
resolvedBuildSettings( )
(
	stylePath=$1
	extraSettings=${2:-}

	assert "[ -n \"${stylePath:-}\" ]" \
		"resolvedBuildSettings() missing path"

	styleSettings=$( _buildSettingsForStyle "$stylePath" )
	hardcodedSettings=$( _hardcodedBuildSettings )
	colorSettings=$( _colorBuildSettings )
	extraQuoted=$( quoteSettings "$extraSettings" )

	if [ -n "$hardcodedSettings" ]
	then
		hardcodedQuoted=$( quoteSettings "$hardcodedSettings" )
			styleSettings=$( appendQuotedSettings "$styleSettings" \
				"$hardcodedQuoted" )
	fi
	if [ -n "$colorSettings" ]
	then
		colorQuoted=$( quoteSettings "$colorSettings" )
			styleSettings=$( appendQuotedSettings "$styleSettings" \
				"$colorQuoted" )
	fi
	if [ -n "$extraQuoted" ]
	then
			styleSettings=$( appendQuotedSettings "$styleSettings" \
				"$extraQuoted" )
	fi

	printf '%s' "$styleSettings"
)
