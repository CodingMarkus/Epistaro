#!/bin/sh

set -eu

[ -n "${__included_build_sh:-}" ] && return 0
__included_build_sh=1


# $1 - Source directory for the file.
# $2 - Quoted build settings string.
#
# Sets workDir and fileFlags for the file build step.
#
_prepareFlags( )
{
	flagsSrcDir=$1
	flagsBuildSettings=$2

	[ "${fileFlagsReady:-0}" -eq 0 ] || return 0
	fileFlagsReady=1

	# Find any compile_flags.txt and read it
	flagsPath=$( findCompileFlags "$flagsSrcDir" )
	flagsDir=""
	dirSettings=""
	if [ -n "$flagsPath" ]
	then
		case "$flagsPath" in
			*/*) flagsDir=${flagsPath%/*} ;;
			*) flagsDir="." ;;
		esac
		dirSettings=$( readCompileFlags "$flagsPath" )
	fi
	dirFlags=$( quoteSettings "$dirSettings" )
	if [ -n "$flagsDir" ]
	then
		workDir=$flagsDir
	else
		workDir=$flagsSrcDir
	fi

	# Create final build flags for the file to build
	fileFlags=$flagsBuildSettings
	if [ -n "$dirFlags" ]
	then
		if [ -n "$fileFlags" ]
		then
			fileFlags="$fileFlags $dirFlags"
		else
			fileFlags=$dirFlags
		fi
	fi

	if [ -z "$fileFlags" ]
	then
		fileFlags="--"
	fi
}


# $1 - Source file path.
# $2 - Object file output path.
# $3 - Source directory for the file.
# $4 - Quoted build settings string.
#
# Prepares flags and compiles the file.
#
_buildFile( )
{
	buildSrcPath=$1
	buildObjPath=$2
	buildSrcDir=$3
	buildSettings=$4

	_prepareFlags "$buildSrcDir" "$buildSettings"
	buildFile "$buildSrcPath" "$buildObjPath" "$workDir" "$fileFlags"
}


# $1 - Target name.
# $2 - Style name.
# $3 - Build output root directory.
# $4 - Quoted build settings string.
#
# Builds all C sources for the target.
#
buildTarget( )
{
	target=$1
	styleName=$2
	buildDir=$3
	buildSettings=$4

	targetDir=targets/$target
	srcRoot=$targetDir/src
	buildTargetDir=$buildDir/builds/$styleName/$target
	objRoot=$buildTargetDir/obj

	[ -d "$objRoot" ] || mkdir -p "$objRoot"
	[ -d "$srcRoot" ] || return 0

	srcRoot=${srcRoot%/}

	find "$srcRoot" -type f -name '*.c' \
		| while IFS= read -r srcPath || [ -n "$srcPath" ]
	do
		[ -n "$srcPath" ] || continue

		relPath=${srcPath#"$srcRoot"/}
		objRel=${relPath%.c}
		objPath=$objRoot/$objRel.o
		depPath=$objRoot/$objRel.dep

		case "$srcPath" in
			*/*) srcDir=${srcPath%/*} ;;
			*) srcDir="." ;;
		esac

		fileFlagsReady=0

		if depFileIsOutdated "$depPath"
		then
			_prepareFlags "$srcDir" "$buildSettings"
			generateDepFile "$srcPath" "$depPath" "$workDir" "$fileFlags"
		fi

		# Object file older than dep file?
		if isOutdated "$objPath" "$depPath"
		then
			_buildFile "$srcPath" "$objPath" "$srcDir" "$buildSettings"
			continue
		fi

		# Check if any dependency has been updated or is missing
		set --
		while IFS= read -r dep || [ -n "$dep" ]
		do
			[ -n "$dep" ] || continue
			case "$dep" in
				/*) depPathResolved=$dep ;;
				*) depPathResolved=$srcDir/$dep ;;
			esac
			set -- "$@" "$depPathResolved"
		done < "$depPath"

		if [ "$#" -eq 0 ]
		then
			_buildFile "$srcPath" "$objPath" "$srcDir" "$buildSettings"
			continue
		fi

		if isOutdated "$objPath" "$@"
		then
			_buildFile "$srcPath" "$objPath" "$srcDir" "$buildSettings"
		fi
	done
}
