#!/bin/sh

set -eu

[ -n "${__included_lib_build_settings_sh:-}" ] && return 0
__included_lib_build_settings_sh=1

. lib_error.sh
. lib_assert.sh

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
			stylePathAbs=$(
				CDPATH='' cd -- "$styleDir" 2>/dev/null && pwd -P
			) || printErrorAndExit "Style dir not found: $styleDir"
			stylePathAbs=$stylePathAbs/$( basename -- "$stylePath" )
			;;
	esac

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
			\$include[[:space:]]* )
				includeLine=${trimmed#\$include}
				includeName=$( printf '%s' "$includeLine" \
					| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' )
				if [ -z "$includeName" ]
				then
					printErrorAndExit "\$include missing name in $stylePath"
				fi
				includePath="$styleDir/$includeName"
				if [ ! -e "$includePath" ]
				then
					printErrorAndExit "\$include style not found: $includeName"
				fi
				expandStyle "$styleDir/$includeName"
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
#
# Prints the path to the nearest compile_flags.txt, searching parent
# directories up to the project root.
#
findCompileFlags( )
(
	srcDir=$1

	assert "[ -n \"${srcDir:-}\" ]" "findCompileFlags() missing source dir"

	projectRoot=${PROJECT_ROOT_DIR:-}
	if [ -z "$projectRoot" ]
	then
		projectRoot=$( pwd -P )
	fi

	case "$projectRoot" in
		/*) ;;
		*)
			projectRoot=$(
				CDPATH='' cd -- "$projectRoot" 2>/dev/null && pwd -P
			) || projectRoot=/
			;;
	esac

	case "$srcDir" in
		/*) searchDir=$srcDir ;;
		*)
			searchDir=$(
				CDPATH='' cd -- "$srcDir" 2>/dev/null && pwd -P
			) || return 0
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
