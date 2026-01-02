#!/bin/sh

set -eu

[ -n "${__included_lib_build_settings_sh:-}" ] && return 0
__included_lib_build_settings_sh=1


. lib_assert.sh
. lib_error.sh
. lib_fs.sh
. lib_platform.sh
. lib_quote.sh
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
	eval "__style_saved_includeStack_$_exp_depth=\${__style_include_stack-}"

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
				|| printErrorAndExit "Style dir not found: $_exp_dir"
			;;
	esac
	_exp_dir_abs=${_exp_path_abs%/*}
	[ -n "$_exp_dir_abs" ] || _exp_dir_abs=/

	_exp_stack=${__style_include_stack:-}
	case ":$_exp_stack:" in
		*":$_exp_path_abs:"*)
			printErrorAndExit "Style include cycle detected: $_exp_path_abs"
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
		_exp_trim=$( printf '%s' "$_exp_line" | sed 's/^[[:space:]]*//' )
		[ -z "$_exp_trim" ] && continue

		case "$_exp_trim" in
			\#*) continue ;;

			\$set[[:space:]]* )
				_exp_set_line=${_exp_trim#"\$set"}
				_exp_split=$( _styleSplitVarAndRest "$_exp_set_line" )
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
					printErrorAndExit "\$set missing name in $_exp_path_for_messages"
				_exp_value=$( _styleParseValue "$_exp_rest" \
					"$_exp_path_for_messages" )
				_styleSetVar "$_exp_name" "$_exp_value" \
					"$_exp_path_for_messages"
				;;
			\$unset[[:space:]]* )
				_exp_unset_line=${_exp_trim#"\$unset"}
				_exp_split=$( _styleSplitVarAndRest "$_exp_unset_line" )
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
						"\$unset missing name in $_exp_path_for_messages"
				_exp_rest=$( _styleTrim "$_exp_rest" )
				[ -z "$_exp_rest" ] || \
					printErrorAndExit \
						"Unexpected text in $_exp_path_for_messages: $_exp_trim"
				_styleUnsetVar "$_exp_name" "$_exp_path_for_messages"
				;;
			\$include\?[[:space:]]*|\
			\$include\?\(*|\
			\$include[[:space:]]*|\
			\$include\(* )
				_exp_inc_opt=0
				case "$_exp_trim" in
					\$include\?*)
						_exp_inc_opt=1
						_exp_inc_line=${_exp_trim#"\$include?"}
						;;
					*)
						_exp_inc_line=${_exp_trim#"\$include"}
						;;
				esac
				_exp_inc_dir="\$include"
				if [ "$_exp_inc_opt" -eq 1 ]
				then
					_exp_inc_dir="\$include?"
				fi
				_exp_inc_line=$( _styleTrimLeft "$_exp_inc_line" )
				_exp_inc_ok=1
				case "$_exp_inc_line" in
					\(* )
						_exp_cond_block=${_exp_inc_line#\(}
						case "$_exp_cond_block" in
							*\)* )
								_exp_cond=${_exp_cond_block%%\)*}
								_exp_after=${_exp_cond_block#"$_exp_cond"}
								_exp_after=${_exp_after#\)}
								_exp_inc_line=$( _styleTrimLeft "$_exp_after" )
								;;
							*)
								printErrorAndExit \
									"Missing ')' in include condition in $_exp_path_for_messages"
								;;
						esac
						if _styleEvalCondition "$_exp_cond" \
							"$_exp_path_for_messages"
						then
							_exp_inc_ok=1
						else
							_exp_inc_ok=0
						fi
						;;
				esac
				_exp_inc_name=$( _styleTrim "$_exp_inc_line" )
					if [ -z "$_exp_inc_name" ]
					then
						printErrorAndExit \
							"$_exp_inc_dir missing name in $_exp_path_for_messages"
					fi
				if [ "$_exp_inc_ok" -eq 0 ]
				then
					continue
				fi
				case "$_exp_inc_name" in
					/*) _exp_inc_path=$_exp_inc_name ;;
					*) _exp_inc_path="$_exp_dir_abs/$_exp_inc_name" ;;
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
								"\$include style not found: $_exp_inc_name"
					fi
				fi
				;;

			\$*)
				printErrorAndExit \
					"Unknown directive in $_exp_path_for_messages: $_exp_trim"
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
		_styleExportCapsVars "$_exp_path"
	fi

	eval "_exp_path=\${__style_saved_stylePath_$_exp_depth-}"
	eval "_exp_dir=\${__style_saved_styleDir_$_exp_depth-}"
	eval "_exp_path_abs=\${__style_saved_stylePathAbs_$_exp_depth-}"
	eval "_exp_dir_abs=\${__style_saved_styleDirAbs_$_exp_depth-}"
	eval "__style_include_stack=\${__style_saved_includeStack_$_exp_depth-}"
	eval "unset __style_saved_stylePath_$_exp_depth \
		__style_saved_styleDir_$_exp_depth \
		__style_saved_stylePathAbs_$_exp_depth \
		__style_saved_styleDirAbs_$_exp_depth \
		__style_saved_includeStack_$_exp_depth"

	_exp_depth=$((_exp_depth - 1))
	if [ "$_exp_depth" -gt 0 ]
	then
		__style_parse_depth=$_exp_depth
	else
		unset __style_parse_depth
	fi
}


# $1 - Source directory to check for compile_flags.txt.
# $2 - Project root directory.
#
# Prints the path to the nearest compile_flags.txt, searching parent
# directories up to the project root.
#
findCompileFlags( )
(
	srcDir=$1
	projectRoot=$2

	assert "[ -n \"${srcDir:-}\" ]" \
		"findCompileFlags() missing source dir"
	assert "[ -n \"${projectRoot:-}\" ]" \
		"findCompileFlags() missing project root dir"

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
readCompileFlags( )
(
	flagsPath=$1

	assert "[ -n \"${flagsPath:-}\" ]" "readCompileFlags() missing flags path"
	assert "[ -f \"$flagsPath\" ]" "compile_flags.txt not found: $flagsPath"

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


# Prints hardcoded build settings (one per line).
#
hardcodedBuildSettings( )
{
	printf '%s\n' "-flto=thin"
}


# Returns success if the terminal supports color diagnostics.
#
_supportsColorDiagnostics( )
{
	[ -t 2 ] || return 1
	command -v tput >/dev/null 2>&1 || return 1

	_scd_colors=$( tput colors 2>/dev/null || printf '' )
	case "$_scd_colors" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$_scd_colors" -gt 0 ] || return 1
}


# Prints color diagnostic flags when supported.
#
colorBuildSettings( )
{
	if _supportsColorDiagnostics
	then
		printf '%s\n' "-fcolor-diagnostics"
	fi
}


# $1 - Build style file path.
#
# Prints the quoted build settings string for the style.
#
buildSettingsForStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" "buildSettingsForStyle() missing path"

	styleSettings=$( expandStyle "$stylePath" )

	quoteSettings "$styleSettings"
)


# $1 - Build style file path.
#
# Prints export/unset commands for all-caps style variables.
#
styleExportsForStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" "styleExportsForStyle() missing path"

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

	_ssv_lines=$( styleExportsForStyle "$_ssv_path" )
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

	assert "[ -n \"${stylePath:-}\" ]" "resolvedBuildSettings() missing path"

	styleSettings=$( buildSettingsForStyle "$stylePath" )
	hardcodedSettings=$( hardcodedBuildSettings )
	colorSettings=$( colorBuildSettings )
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
		styleSettings=$( appendQuotedSettings "$styleSettings" "$colorQuoted" )
	fi
	if [ -n "$extraQuoted" ]
	then
		styleSettings=$( appendQuotedSettings "$styleSettings" "$extraQuoted" )
	fi

	printf '%s' "$styleSettings"
)
