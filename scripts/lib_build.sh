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
. lib_sanitize.sh

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
	flags_dirFlags=""
	sanitizeSettings=""

	if [ "${__cached_flags_path:-}" = "$flags_path" ]
	then
		flags_dir=${__cached_flags_dir:-}
		flags_dirFlags=${__cached_flags_dirFlags:-}
		sanitizeSettings=${__cached_sanitizeSettings:-}
	else
		flags_dirSettings=""
		if [ -n "$flags_path" ]
		then
			case "$flags_path" in
				*/*) flags_dir=${flags_path%/*} ;;
				*) flags_dir="." ;;
			esac
			flags_dirSettings=$( readCompileFlags "$flags_path" )
		fi
		sanitizeSettings=$( _sanitizeSettingsFromList "$flags_dirSettings" )
		flags_dirFlags=$( quoteSettings "$flags_dirSettings" )
		__cached_flags_path=$flags_path
		__cached_flags_dir=$flags_dir
		__cached_flags_dirFlags=$flags_dirFlags
		__cached_sanitizeSettings=$sanitizeSettings
	fi

	if [ -n "$sanitizeSettings" ]
	then
		applySanitize=1
		if [ -n "$flags_path" ]
		then
			case "
${targetSanitizePaths:-}
" in
				*"
$flags_path
"*) applySanitize= ;;
			esac
		fi
		if [ -n "$applySanitize" ]
		then
			while IFS= read -r sanitizeFlag || [ -n "$sanitizeFlag" ]
			do
				[ -n "$sanitizeFlag" ] || continue
				_addTargetSanitizeSetting "$sanitizeFlag"
			done <<EOF
$sanitizeSettings
EOF
			if [ -n "$flags_path" ]
			then
				if [ -n "${targetSanitizePaths:-}" ]
				then
					targetSanitizePaths="$targetSanitizePaths
$flags_path"
				else
					targetSanitizePaths=$flags_path
				fi
			fi
		fi
	fi
	if [ -n "$flags_dir" ]
	then
		workDir=$flags_dir
	else
		workDir=$flags_srcDir
	fi

	# Create final build flags for the file to build
	fileFlags=$( appendQuotedSettings "$flags_buildSettings" "$flags_dirFlags" )

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
#
# Copies public headers for library targets into the build include dir.
#
_syncPublicHeaders( )
(
	projectRoot=$1
	target=$2
	targetStyleName=$3
	buildDir=$4

	assert "[ -n \"${projectRoot:-}\" ]" \
		"_syncPublicHeaders() missing project dir"
	assert "[ -n \"${target:-}\" ]" "_syncPublicHeaders() missing target"
	assert "[ -n \"${targetStyleName:-}\" ]" \
		"_syncPublicHeaders() missing style name"
	assert "[ -n \"${buildDir:-}\" ]" "_syncPublicHeaders() missing build dir"

	targetDir=$projectRoot/targets/$target
	srcInc=$targetDir/inc
	outInc=$( buildTargetIncDirPath "$buildDir" "$targetStyleName" "$target" )

	if [ -d "$srcInc" ]
	then
		if command -v rsync >/dev/null 2>&1
		then
			[ -d "$outInc" ] || mkdir -p "$outInc"
			rsync -au --delete -q "$srcInc"/ "$outInc"/
		else
			if [ -e "$outInc" ]
			then
				rm -rf "$outInc"
			fi
			cp -Rp "$srcInc" "$outInc"
		fi
	else
		if [ -e "$outInc" ]
		then
			rm -rf "$outInc"
		fi
	fi
)


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

	buildSanitizeSettings=$( _sanitizeSettingsFromQuoted "$targetBuildSettings" )
	targetSanitizeSettings=""
	targetSanitizePaths=""

	[ -d "$objRoot" ] || mkdir -p "$objRoot"

	printf '\n====== Building Target %s ======\n\n' "$target"
	printf 'Using Build Style: %s\n\n' "$targetStyleName"

		if [ -d "$srcRoot" ]
		then
			srcRoot=${srcRoot%/}

			firstCompile=1
			while IFS= read -r srcPath || [ -n "$srcPath" ]
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
				if [ "$firstCompile" -eq 0 ]
				then
					printf '\n'
				fi
				firstCompile=0
				printf 'Compiling %s...\n' "$relPath"
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
				if [ "$firstCompile" -eq 0 ]
				then
					printf '\n'
				fi
				firstCompile=0
				printf 'Compiling %s...\n' "$relPath"
				_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
					"$targetBuildSettings"
				continue
			fi

			if isOutdated "$objPath" "$@"
			then
				if [ "$firstCompile" -eq 0 ]
				then
					printf '\n'
				fi
				firstCompile=0
				printf 'Compiling %s...\n' "$relPath"
				_buildFile "$projectRoot" "$srcPath" "$objPath" "$srcDir" \
					"$targetBuildSettings"
			fi
			done <<EOF
$( find "$srcRoot" -type f -name '*.c' )
EOF
		fi

	buildTargetOutput "$projectRoot" "$target" "$targetStyleName" "$buildDir" \
		"$targetBuildSettings" "$targetSanitizeSettings"

	case "$target" in
		*.lib)
			printf 'Copying Public Headers...\n'
			_syncPublicHeaders "$projectRoot" "$target" \
				"$targetStyleName" "$buildDir"
			;;
	esac

	printf 'Done.\n'
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
# $6 - Sanitizer settings string containing one entry per line.
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
	targetSanitizeSettings=$6

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

	linkFlags=""
	if [ -n "${targetSanitizeSettings:-}" ]
	then
		sanitizeFlags=$( quoteSettings "$targetSanitizeSettings" )
		if [ -n "$sanitizeFlags" ]
		then
			linkFlags=$( appendQuotedSettings "$linkFlags" "$sanitizeFlags" )
		fi
	fi
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
				printf 'Pre-Linking %s...\n' "${prelinkPath##*/}"
				prelinkObjects "$prelinkPath" "$projectRoot" \
					"$linkFlags" "$@"
			fi

			if isOutdated "$staticPath" "$prelinkPath"
			then
				printf 'Creating archive %s...\n' "${staticPath##*/}"
				createStaticLibraryFromObjects "$staticPath" \
					"$projectRoot" "$prelinkPath"
			fi

			if isOutdated "$dynamicPath" "$prelinkPath"
			then
				printf 'Linking %s...\n' "${dynamicPath##*/}"
				linkDynamicLibrary "$dynamicPath" "$projectRoot" \
					"$linkFlags" "$prelinkPath"
			fi
			;;

		*.bin)
			binPath=$targetDir/$target
			if isOutdated "$binPath" "$@"
			then
				printf 'Linking %s...\n' "${binPath##*/}"
				linkBinary "$binPath" "$projectRoot" "$linkFlags" \
					"$@"
			fi
			;;

		*)
			printErrorAndExit "Unknown target type: $target"
			;;
	esac
)
