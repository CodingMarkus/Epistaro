#!/bin/sh

set -eu

[ -n "${__included_lib_build_sh:-}" ] && return 0
__included_lib_build_sh=1


. lib_ar.sh
. lib_build_settings.sh
. lib_clang.sh
. lib_outdated.sh
. lib_paths.sh
. lib_quote.sh


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
	targetStyleName=$3
	buildDir=$4
	targetBuildSettings=$5

	assert "[ -n \"${projectRoot:-}\" ]" "buildTarget() missing project dir"

	targetDir=$projectRoot/targets/$target
	srcRoot=$targetDir/src
	objRoot=$( buildTargetObjSrcDirPath "$buildDir" "$targetStyleName" "$target" )

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
			_prepareFlags "$projectRoot" "$srcDir" "$targetBuildSettings"
			generateDepFile "$srcPath" "$depPath" "$workDir" "$fileFlags"
		fi

		# Object file older than dep file?
		if isOutdated "$objPath" "$depPath"
		then
			_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
				"$targetBuildSettings"
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
				"$targetBuildSettings"
			continue
		fi

		if isOutdated "$objPath" "$@"
		then
			_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
				"$targetBuildSettings"
		fi
	done
)


# $1 - Output static library path.
# $2 - Working directory for clang.
# $3 - clang flags string, already quoted for eval.
# $4.. - Object file paths.
#
# Pre-links objects into a single object file, then archives it.
#
createStaticLibrary( )
(
	outPath=$1
	workDir=$2
	flags=$3
	shift 3

	assert "[ -n \"${outPath:-}\" ]" "createStaticLibrary() missing output path"
	assert "[ -n \"${workDir:-}\" ]" "createStaticLibrary() missing work dir"
	assert "[ -n \"${flags:-}\" ]" "createStaticLibrary() missing flags"
	assert "[ $# -gt 0 ]" "createStaticLibrary() missing object files"

	prelinkPath=$outPath.prelink.o
	prelinkObjects "$prelinkPath" "$workDir" "$flags" "$@"
	createStaticLibraryFromObjects "$outPath" "$workDir" "$prelinkPath"
)


_dynamicLibExtension( )
{
	if command -v uname >/dev/null 2>&1
	then
		case "$( uname -s 2>/dev/null )" in
			Darwin) printf '%s\n' ".dylib" ;;
			*) printf '%s\n' ".so" ;;
		esac
	else
		printf '%s\n' ".so"
	fi
}


# $1 - Project root directory.
# $2 - Target name.
# $3 - Style name.
# $4 - Build output root directory.
# $5 - Quoted build settings string.
#
# Links final target outputs based on target name extension.
#
buildTargetOutput( )
(
	projectRoot=$1
	target=$2
	targetStyleName=$3
	buildDir=$4
	targetBuildSettings=$5

	assert "[ -n \"${projectRoot:-}\" ]" \
		"buildTargetOutput() missing project dir"
	assert "[ -n \"${target:-}\" ]" "buildTargetOutput() missing target"
	assert "[ -n \"${targetStyleName:-}\" ]" \
		"buildTargetOutput() missing style name"
	assert "[ -n \"${buildDir:-}\" ]" \
		"buildTargetOutput() missing build dir"

	targetDir=$( buildTargetDirPath "$buildDir" "$targetStyleName" "$target" )
	objDir=$( buildTargetObjDirPath "$buildDir" "$targetStyleName" "$target" )
	objSrcRoot=$( buildTargetObjSrcDirPath "$buildDir" \
		"$targetStyleName" "$target" )

	[ -d "$objSrcRoot" ] || return 0

	set --
	while IFS= read -r objPath || [ -n "$objPath" ]
	do
		[ -n "$objPath" ] || continue
		set -- "$@" "$objPath"
	done <<EOF
$( find "$objSrcRoot" -type f -name '*.o' -print )
EOF

	[ $# -gt 0 ] || return 0

	linkFlags=$targetBuildSettings
	if [ -z "$linkFlags" ]
	then
		linkFlags="--"
	fi

	case "$target" in
		*.lib)
			prelinkPath=$objDir/$target
			staticPath=$targetDir/$target
			dynamicPath=$targetDir/${target%.lib}$( _dynamicLibExtension )

			if isOutdated "$prelinkPath" "$@"
			then
				prelinkObjects "$prelinkPath" "$projectRoot" \
					"$linkFlags" "$@"
			fi

			if isOutdated "$staticPath" "$prelinkPath"
			then
				createStaticLibraryFromObjects "$staticPath" \
					"$projectRoot" "$prelinkPath"
			fi

			if isOutdated "$dynamicPath" "$prelinkPath"
			then
				linkDynamicLibrary "$dynamicPath" "$projectRoot" \
					"$linkFlags" "$prelinkPath"
			fi
			;;
		*.bin)
			binPath=$targetDir/$target
			if isOutdated "$binPath" "$@"
			then
				linkBinary "$binPath" "$projectRoot" "$linkFlags" \
					"$@"
			fi
			;;
		*)
			printErrorAndExit "Unknown target type: $target"
			;;
	esac
)
