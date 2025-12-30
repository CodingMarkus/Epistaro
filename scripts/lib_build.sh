#!/bin/sh

set -eu

[ -n "${__included_lib_build_sh:-}" ] && return 0
__included_lib_build_sh=1


. lib_build_settings.sh
. lib_quote.sh
. lib_clang.sh
. lib_outdated.sh
. lib_paths.sh


# $1 - Project root directory.
# $2 - Source directory for the file.
# $3 - Quoted build settings string.
#
# Sets workDir and fileFlags for the file build step.
#
_prepareFlags( )
{
	flags_projectRoot=$1
	flags_srcDir=$2
	flags_buildSettings=$3

	[ "${fileFlagsReady:-0}" -eq 0 ] || return 0
	fileFlagsReady=1

	# Find any compile_flags.txt and read it
	flags_path=$( findCompileFlags "$flags_srcDir" "$flags_projectRoot" )
	flags_dir=""
	flags_dirSettings=""
	if [ -n "$flags_path" ]
	then
		case "$flags_path" in
			*/*) flags_dir=${flags_path%/*} ;;
			*) flags_dir="." ;;
		esac
		flags_dirSettings=$( readCompileFlags "$flags_path" )
	fi
	flags_dirFlags=$( quoteSettings "$flags_dirSettings" )
	if [ -n "$flags_dir" ]
	then
		workDir=$flags_dir
	else
		workDir=$flags_srcDir
	fi

	# Create final build flags for the file to build
	fileFlags=$flags_buildSettings
	if [ -n "$flags_dirFlags" ]
	then
		if [ -n "$fileFlags" ]
		then
			fileFlags="$fileFlags $flags_dirFlags"
		else
			fileFlags=$flags_dirFlags
		fi
	fi

	if [ -z "$fileFlags" ]
	then
		fileFlags="--"
	fi
}


# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Source directory for the file.
# $5 - Quoted build settings string.
#
# Prepares flags and compiles the file.
#
_buildFile( )
{
	build_projectRoot=$1
	build_srcPath=$2
	build_objPath=$3
	build_srcDir=$4
	build_settings=$5

	_prepareFlags "$build_projectRoot" "$build_srcDir" "$build_settings"
	buildFile "$build_srcPath" "$build_objPath" "$workDir" "$fileFlags"
}


# $1 - Project root directory.
# $2 - Target name.
# $3 - Style name.
# $4 - Build output root directory.
# $5 - Quoted build settings string.
#
# Builds all C sources for the target.
#
buildTarget( )
(
	projectRoot=$1
	target=$2
	styleName=$3
	buildDir=$4
	buildSettings=$5

	assert "[ -n \"${projectRoot:-}\" ]" "buildTarget() missing project dir"

	targetDir=$projectRoot/targets/$target
	srcRoot=$targetDir/src
	objRoot=$( buildTargetObjDirPath "$buildDir" "$styleName" "$target" )

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
			_prepareFlags "$projectRoot" "$srcDir" "$buildSettings"
			generateDepFile "$srcPath" "$depPath" "$workDir" "$fileFlags"
		fi

		# Object file older than dep file?
		if isOutdated "$objPath" "$depPath"
		then
			_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
				"$buildSettings"
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
			_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
				"$buildSettings"
			continue
		fi

		if isOutdated "$objPath" "$@"
		then
			_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
				"$buildSettings"
		fi
	done
)
