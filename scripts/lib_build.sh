#!/bin/sh

set -eu

[ -n "${__included_lib_build_sh:-}" ] && return 0
__included_lib_build_sh=1


. lib_ar.sh
. lib_build_settings.sh
. lib_clang.sh
. lib_outdated.sh
. lib_paths.sh
. lib_platform.sh
. lib_quote.sh
. lib_sanitize.sh

# $1 - Project root directory.
# $2 - Source directory for the file.
# $3 - Quoted build settings string.
#
# Sets __workDir and __fileFlags for the file build step.
#
_prepareFlags( )
{
	_flags_projectRoot=$1
	_flags_srcDir=$2
	_flags_buildSettings=$3

	[ "${__fileFlagsReady:-0}" -eq 0 ] || return 0
	__fileFlagsReady=1

	# Find any compile_flags.txt and read it
	_flags_path=$( findCompileFlags "$_flags_srcDir" "$_flags_projectRoot" )
	_flags_dir=""
	_flags_dirFlags=""
	_flags_sanitizeSettings=""

	if [ "${__cached_flags_path:-}" = "$_flags_path" ]
	then
		_flags_dir=${__cached_flags_dir:-}
		_flags_dirFlags=${__cached_flags_dirFlags:-}
		_flags_sanitizeSettings=${__cached_sanitizeSettings:-}
	else
		_flags_dirSettings=""
		if [ -n "$_flags_path" ]
		then
			case "$_flags_path" in
				*/*) _flags_dir=${_flags_path%/*} ;;
				*) _flags_dir="." ;;
			esac
			_flags_dirSettings=$( readCompileFlags "$_flags_path" )
		fi
		_flags_sanitizeSettings=$( _sanitizeSettingsFromList "$_flags_dirSettings" )
		_flags_dirFlags=$( quoteSettings "$_flags_dirSettings" )
		__cached_flags_path=$_flags_path
		__cached_flags_dir=$_flags_dir
		__cached_flags_dirFlags=$_flags_dirFlags
		__cached_sanitizeSettings=$_flags_sanitizeSettings
	fi

	if [ -n "$_flags_sanitizeSettings" ]
	then
		_flags_applySanitize=1
		if [ -n "$_flags_path" ]
		then
			case "
${__targetSanitizePaths:-}
" in
				*"
$_flags_path
"*) _flags_applySanitize= ;;
			esac
		fi
		if [ -n "$_flags_applySanitize" ]
		then
			while IFS= read -r _flags_sanitizeFlag || \
				[ -n "$_flags_sanitizeFlag" ]
			do
				[ -n "$_flags_sanitizeFlag" ] || continue
				_addTargetSanitizeSetting "$_flags_sanitizeFlag"
			done <<EOF
$_flags_sanitizeSettings
EOF
			if [ -n "$_flags_path" ]
			then
				if [ -n "${__targetSanitizePaths:-}" ]
				then
					__targetSanitizePaths="$__targetSanitizePaths
$_flags_path"
				else
					__targetSanitizePaths=$_flags_path
				fi
			fi
		fi
	fi
	if [ -n "$_flags_dir" ]
	then
		__workDir=$_flags_dir
	else
		__workDir=$_flags_srcDir
	fi

	# Create final build flags for the file to build
	__fileFlags=$( appendQuotedSettings "$_flags_buildSettings" \
		"$_flags_dirFlags" )

	if [ -z "$__fileFlags" ]
	then
		__fileFlags="--"
	fi
}


# Prints linker flags for deploy post-processing.
#
_deployPostprocessFlags( )
{
	if platformTargetIsApple
	then
		printf '%s\n' "-Wl,-dead_strip"
		printf '%s\n' "-Wl,-S"
		printf '%s\n' "-Wl,-x"
	else
		printf '%s\n' "-Wl,--gc-sections"
		printf '%s\n' "-Wl,--strip-debug"
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
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_srcDir=$4
	_build_settings=$5

	_prepareFlags "$_build_projectRoot" "$_build_srcDir" "$_build_settings"
	buildFile "$_build_srcPath" "$_build_objPath" "$__workDir" "$__fileFlags"
}

# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Source directory for the file.
# $5 - Quoted build settings string.
#
# Runs a build and captures clang diagnostics to control compile spacing.
#
_buildFileWithOutput( )
{
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_srcDir=$4
	_build_settings=$5

	_build_tmpPath=$( mktemp "${TMPDIR:-/tmp}/build.XXXXXX" ) \
		|| printErrorAndExit "mktemp failed"

	if _buildFile "$_build_projectRoot" "$_build_srcPath" "$_build_objPath" \
		"$_build_srcDir" "$_build_settings" 2>"$_build_tmpPath"
	then
		_build_status=0
	else
		_build_status=$?
	fi

	if [ -s "$_build_tmpPath" ]
	then
		cat "$_build_tmpPath" >&2
		__buildFileHadOutput=1
	else
		__buildFileHadOutput=0
	fi
	rm -f "$_build_tmpPath"

	if [ "$_build_status" -ne 0 ]
	then
		return "$_build_status"
	fi
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

	__buildSanitizeSettings=$( _sanitizeSettingsFromQuoted "$targetBuildSettings" )
	__targetSanitizeSettings=""
	__targetSanitizePaths=""

	[ -d "$objRoot" ] || mkdir -p "$objRoot"

	printf '\n====== Building Target %s ======\n\n' "$target"
	printf 'Using Build Style: %s\n\n' "$targetStyleName"

		if [ -d "$srcRoot" ]
		then
			srcRoot=${srcRoot%/}

			compileSpacing=0
			compiledAny=0
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

			__fileFlagsReady=0

			if depFileIsOutdated "$depPath"
			then
				_prepareFlags "$projectRoot" "$srcDir" "$targetBuildSettings"
				generateDepFile "$srcPath" "$depPath" "$__workDir" "$__fileFlags"
			fi

			# Object file older than dep file?
			if isOutdated "$objPath" "$depPath"
			then
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_buildFileWithOutput "$projectRoot" "$srcPath" "$objPath" \
					"$srcDir" "$targetBuildSettings"
				compileSpacing=$__buildFileHadOutput
				compiledAny=1
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
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_buildFileWithOutput "$projectRoot" "$srcPath" "$objPath" \
					"$srcDir" "$targetBuildSettings"
				compileSpacing=$__buildFileHadOutput
				compiledAny=1
				continue
			fi

			if isOutdated "$objPath" "$@"
			then
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_buildFileWithOutput "$projectRoot" "$srcPath" "$objPath" \
					"$srcDir" "$targetBuildSettings"
				compileSpacing=$__buildFileHadOutput
				compiledAny=1
			fi
			done <<EOF
$( find "$srcRoot" -type f -name '*.c' )
EOF
		fi

	buildTargetOutput "$projectRoot" "$target" "$targetStyleName" "$buildDir" \
		"$targetBuildSettings" "$__targetSanitizeSettings"

	case "$target" in
		*.lib)
			printf 'Copying Public Headers...\n'
			_syncPublicHeaders "$projectRoot" "$target" \
				"$targetStyleName" "$buildDir"
			printf '\n'
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
	__workDir=$2
	flags=$3
	shift 3

	assert "[ -n \"${outPath:-}\" ]" "createStaticLibrary() missing output path"
	assert "[ -n \"${__workDir:-}\" ]" "createStaticLibrary() missing work dir"
	assert "[ -n \"${flags:-}\" ]" "createStaticLibrary() missing flags"
	assert "[ $# -gt 0 ]" "createStaticLibrary() missing object files"

	prelinkPath=$outPath.prelink.o
	prelinkObjects "$prelinkPath" "$__workDir" "$flags" "$@"
	createStaticLibraryFromObjects "$outPath" "$__workDir" "$prelinkPath"
)


# Prints the dynamic library extension for the current platform.
#
_dynamicLibExtension( )
{
	if platformTargetIsApple
	then
		printf '%s\n' ".dylib"
	elif platformTargetIsWindows
	then
		printf '%s\n' ".dll"
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
	__targetSanitizeSettings=$6

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

	baseLinkFlags=""
	majorSpacingDone=0
	if [ -n "${__targetSanitizeSettings:-}" ]
	then
		sanitizeFlags=$( quoteSettings "$__targetSanitizeSettings" )
		if [ -n "$sanitizeFlags" ]
		then
			baseLinkFlags=$( appendQuotedSettings "$baseLinkFlags" \
				"$sanitizeFlags" )
		fi
	fi
	finalLinkFlags=$baseLinkFlags
	if [ -n "${__style_set_DEPLOY_PROCESSING+x}" ]
	then
		postFlags=$( _deployPostprocessFlags )
		if [ -n "$postFlags" ]
		then
			postFlagsQuoted=$( quoteSettings "$postFlags" )
			finalLinkFlags=$( appendQuotedSettings "$finalLinkFlags" \
				"$postFlagsQuoted" )
		fi
	fi
	if [ -z "$baseLinkFlags" ]
	then
		baseLinkFlags="--"
	fi
	if [ -z "$finalLinkFlags" ]
	then
		finalLinkFlags="--"
	fi

	case "$target" in
		*.lib)
			prelinkPath=$objDir/${target%.*}.o
			staticPath=$targetDir/${target%.*}.a
			dynamicPath=$targetDir/${target%.lib}$( _dynamicLibExtension )

			if isOutdated "$prelinkPath" "$@"
			then
				if [ "${compiledAny:-0}" -eq 1 ] \
					&& [ "$majorSpacingDone" -eq 0 ]
				then
					printf '\n'
					majorSpacingDone=1
				fi
				printf 'Pre-Linking %s...\n' "${prelinkPath##*/}"
				prelinkObjects "$prelinkPath" "$projectRoot" \
					"$baseLinkFlags" "$@"
				printf '\n'
			fi

			if isOutdated "$staticPath" "$prelinkPath"
			then
				if [ "${compiledAny:-0}" -eq 1 ] \
					&& [ "$majorSpacingDone" -eq 0 ]
				then
					printf '\n'
					majorSpacingDone=1
				fi
				printf 'Creating archive %s...\n' "${staticPath##*/}"
				createStaticLibraryFromObjects "$staticPath" \
					"$projectRoot" "$prelinkPath"
				printf '\n'
			fi

			if isOutdated "$dynamicPath" "$prelinkPath"
			then
				if [ "${compiledAny:-0}" -eq 1 ] \
					&& [ "$majorSpacingDone" -eq 0 ]
				then
					printf '\n'
					majorSpacingDone=1
				fi
				printf 'Linking %s...\n' "${dynamicPath##*/}"
				linkDynamicLibrary "$dynamicPath" "$projectRoot" \
					"$finalLinkFlags" "$prelinkPath"
				printf '\n'
			fi
			;;

		*.bin)
			binPath=$targetDir/$target
			if isOutdated "$binPath" "$@"
			then
				if [ "${compiledAny:-0}" -eq 1 ] \
					&& [ "$majorSpacingDone" -eq 0 ]
				then
					printf '\n'
					majorSpacingDone=1
				fi
				printf 'Linking %s...\n' "${binPath##*/}"
				linkBinary "$binPath" "$projectRoot" "$finalLinkFlags" \
					"$@"
				printf '\n'
			fi
			;;

		*)
			printErrorAndExit "Unknown target type: $target"
			;;
	esac
)
