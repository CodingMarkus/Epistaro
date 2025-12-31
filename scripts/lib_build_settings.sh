#!/bin/sh

set -eu

[ -n "${__included_lib_build_settings_sh:-}" ] && return 0
__included_lib_build_settings_sh=1


. lib_assert.sh
. lib_error.sh
. lib_quote.sh


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

			\$include[[:space:]]* )
				includeLine=${trimmed#\$include}
				includeName=$( printf '%s' "$includeLine" \
					| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' )
				if [ -z "$includeName" ]
				then
					printErrorAndExit "\$include missing name in $stylePath"
				fi
				case "$includeName" in
					/*) includePath=$includeName ;;
					*) includePath="$styleDirAbs/$includeName" ;;
				esac
				if [ ! -e "$includePath" ]
				then
					printErrorAndExit "\$include style not found: $includeName"
				fi
				expandStyle "$includePath"
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
	projectRoot=$2

	assert "[ -n \"${srcDir:-}\" ]" \
		"findCompileFlags() missing source dir"
	assert "[ -n \"${projectRoot:-}\" ]" \
		"findCompileFlags() missing project root dir"

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


# Prints hardcoded build settings (one per line).
#
hardcodedBuildSettings( )
{
	printf '%s\n' "-flto=thin"
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
	hardcodedSettings=$( hardcodedBuildSettings )
	if [ -n "$hardcodedSettings" ]
	then
		if [ -n "$styleSettings" ]
		then
			styleSettings="$styleSettings
$hardcodedSettings"
		else
			styleSettings=$hardcodedSettings
		fi
	fi

	quoteSettings "$styleSettings"
)
