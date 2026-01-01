#!/bin/sh

set -eu

[ -n "${__included_lib_build_settings_sh:-}" ] && return 0
__included_lib_build_settings_sh=1


. lib_assert.sh
. lib_error.sh
. lib_fs.sh
. lib_quote.sh
. lib_style.sh


# $1 - Build style file path.
#
# Prints expanded build styles
#
expandStyle( )
(
	stylePath=$1

	assert "[ -n \"${stylePath:-}\" ]" "expandStyle() missing style path"
	assert "[ -e \"$stylePath\" ]" "style file not found: $stylePath"

	case "$stylePath" in
		*/*) styleDir=${stylePath%/*} ;;
		*) styleDir="." ;;
	esac
	case "$stylePath" in
		/*) stylePathAbs=$stylePath ;;

		*)
			stylePathAbs=$( abs_path "$stylePath" ) \
				|| printErrorAndExit "Style dir not found: $styleDir"
			;;
	esac
	styleDirAbs=${stylePathAbs%/*}
	[ -n "$styleDirAbs" ] || styleDirAbs=/

	includeStack=${__style_include_stack:-}
	case ":$includeStack:" in
		*":$stylePathAbs:"*)
			printErrorAndExit "Style include cycle detected: $stylePathAbs"
			;;
	esac
	if [ -n "$includeStack" ]
	then
		__style_include_stack="$includeStack:$stylePathAbs"
	else
		__style_include_stack=$stylePathAbs
	fi

	while IFS= read -r line || [ -n "$line" ]
	do
		trimmed=$( printf '%s' "$line" | sed 's/^[[:space:]]*//' )
		[ -z "$trimmed" ] && continue

		case "$trimmed" in
			\#*) continue ;;

			\$set[[:space:]]* )
				setLine=${trimmed#'$set'}
				split=$( _style_split_var_and_rest "$setLine" )
				oldIFS=$IFS
				IFS='
'
				set -- $split
				IFS=$oldIFS
				varName=${1-}
				rest=${2-}
				[ -n "$varName" ] || \
					printErrorAndExit "\$set missing name in $stylePath"
				value=$( _style_parse_value "$rest" "$stylePath" )
				_style_set_var "$varName" "$value" "$stylePath"
				;;
			\$unset[[:space:]]* )
				unsetLine=${trimmed#'$unset'}
				split=$( _style_split_var_and_rest "$unsetLine" )
				oldIFS=$IFS
				IFS='
'
				set -- $split
				IFS=$oldIFS
				varName=${1-}
				rest=${2-}
				[ -n "$varName" ] || \
					printErrorAndExit "\$unset missing name in $stylePath"
				rest=$( _style_trim "$rest" )
				[ -z "$rest" ] || \
					printErrorAndExit "Unexpected text in $stylePath: $trimmed"
				_style_unset_var "$varName" "$stylePath"
				;;
			\$include\?[[:space:]]*|\
			\$include\?\(*|\
			\$include[[:space:]]*|\
			\$include\(* )
				includeOptional=0
				case "$trimmed" in
					\$include\?*)
						includeOptional=1
						includeLine=${trimmed#'$include?'}
						;;
					*)
						includeLine=${trimmed#'$include'}
						;;
				esac
				includeDirective='$include'
				if [ "$includeOptional" -eq 1 ]
				then
					includeDirective='$include?'
				fi
				includeLine=$( _style_trim_left "$includeLine" )
				includeOk=1
				case "$includeLine" in
					\(* )
						condBlock=${includeLine#\(}
						case "$condBlock" in
							*\)* )
								cond=${condBlock%%\)*}
								after=${condBlock#"$cond"}
								after=${after#\)}
								includeLine=$( _style_trim_left "$after" )
								;;
							*)
								printErrorAndExit \
									"Missing ')' in include condition in $stylePath"
								;;
						esac
						if _style_eval_condition "$cond" "$stylePath"
						then
							includeOk=1
						else
							includeOk=0
						fi
						;;
				esac
				includeName=$( _style_trim "$includeLine" )
				if [ -z "$includeName" ]
				then
					printErrorAndExit \
						"$includeDirective missing name in $stylePath"
				fi
				if [ "$includeOk" -eq 0 ]
				then
					continue
				fi
				case "$includeName" in
					/*) includePath=$includeName ;;
					*) includePath="$styleDirAbs/$includeName" ;;
				esac
				if [ -e "$includePath" ]
				then
					expandStyle "$includePath"
				else
					if [ "$includeOptional" -eq 1 ]
					then
						:
					else
						printErrorAndExit \
							"\$include style not found: $includeName"
					fi
				fi
				;;

			\$*)
				printErrorAndExit "Unknown directive in $stylePath: $trimmed"
				;;

			*)
				printf '%s\n' "$trimmed"
				;;
		esac
	done < "$stylePath"
)


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
			projectRoot=$( abs_dir "$projectRoot" ) || projectRoot=/
			;;
	esac

	case "$srcDir" in
		/*) searchDir=$srcDir ;;

		*)
			searchDir=$( abs_dir "$srcDir" ) || return 0
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

	colors=$( tput colors 2>/dev/null || printf '' )
	case "$colors" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$colors" -gt 0 ] || return 1
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
