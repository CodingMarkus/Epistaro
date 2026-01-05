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

# $1 - Variable name.
# $2 - Value.
#
# Sets a variable to the provided value.
#
_setVar( )
{
	_sv_name=$1
	_sv_value=$2

	case "$_sv_name" in
		''|*[!A-Za-z0-9_]*)
			printErrorAndExit "Invalid variable name: $_sv_name"
			;;
	esac

	if [ -n "$_sv_value" ]
	then
		_sv_quoted=$( quote "$_sv_value" )
		eval "$_sv_name=$_sv_quoted"
	else
		eval "$_sv_name="
	fi
}


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
_prepareFlags( )
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
	_pf_flags_path=$( findCompileFlags "$_pf_src_dir" "$_pf_project_root" )
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
			_pf_flags_dir_settings=$( readCompileFlags \
				"$_pf_flags_path" )
		fi
		_pf_flags_sanitize_settings=$( _sanitizeSettingsFromList \
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
					_addTargetSanitizeSetting \
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

	_setVar "$_pf_out_work" "$_pf_work_dir"
	_setVar "$_pf_out_flags" "$_pf_file_flags"
	_setVar "$_pf_out_target" "$_pf_target_sanitize_result"
	_setVar "$_pf_out_paths" "$_pf_target_paths_result"
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


# $1 - Quoted build settings string.
# $2 - Target sanitizer settings list.
#
# Prints quoted sanitizer flags for linking.
#
_linkSanitizeFlagsFromSettings( )
(
	_lsf_build_settings=$1
	_lsf_target_sanitize=$2

	_lsf_build_sanitize=$( _sanitizeSettingsFromQuoted \
		"$_lsf_build_settings" )
	_lsf_link_sanitize=$_lsf_build_sanitize
	if [ -n "$_lsf_target_sanitize" ]
	then
		while IFS= read -r _lsf_flag || [ -n "$_lsf_flag" ]
		do
			[ -n "$_lsf_flag" ] || continue
			_lsf_link_sanitize=$(
				_addTargetSanitizeSetting \
					"$_lsf_build_sanitize" \
					"$_lsf_link_sanitize" \
					"$_lsf_flag"
			)
		done <<EOF
$_lsf_target_sanitize
EOF
	fi

	if [ -n "$_lsf_link_sanitize" ]
	then
		quoteSettings "$_lsf_link_sanitize"
	fi
)


# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Work directory for the file.
# $5 - Quoted file flags string.
#
# Prepares flags and compiles the file.
#
_buildFile( )
{
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_workDir=$4
	_build_fileFlags=$5

	buildFile "$_build_srcPath" "$_build_objPath" \
		"$_build_workDir" "$_build_fileFlags"
}

# $1 - Project root directory.
# $2 - Source file path.
# $3 - Object file output path.
# $4 - Work directory for the file.
# $5 - Quoted file flags string.
# $6 - Output variable for compile output flag.
#
# Runs a build and captures clang diagnostics to control compile spacing.
#
_buildFileWithOutput( )
{
	_build_projectRoot=$1
	_build_srcPath=$2
	_build_objPath=$3
	_build_workDir=$4
	_build_fileFlags=$5
	_build_out_had_output=$6

	_build_tmpPath=$( mktemp "${TMPDIR:-/tmp}/build.XXXXXX" ) \
		|| printErrorAndExit "mktemp failed"

	if _buildFile "$_build_projectRoot" "$_build_srcPath" \
		"$_build_objPath" "$_build_workDir" \
		"$_build_fileFlags" 2>"$_build_tmpPath"
	then
		_build_status=0
	else
		_build_status=$?
	fi

	if [ -s "$_build_tmpPath" ]
	then
		cat "$_build_tmpPath" >&2
		_build_had_output=1
	else
		_build_had_output=0
	fi
	rm -f "$_build_tmpPath"

	_setVar "$_build_out_had_output" "$_build_had_output"

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
assert "[ -n \"${buildDir:-}\" ]" \
	"_syncPublicHeaders() missing build dir"

	targetDir=$projectRoot/targets/$target
	srcInc=$targetDir/inc
outInc=$( buildTargetIncDirPath "$buildDir" \
	"$targetStyleName" "$target" )

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

assert "[ -n \"${projectRoot:-}\" ]" \
	"buildTarget() missing project dir"

	targetDir=$projectRoot/targets/$target
	srcRoot=$targetDir/src
	objRoot=$( buildTargetObjSrcDirPath "$buildDir" \
		"$targetStyleName" "$target" )

	buildSanitizeSettings=$( _sanitizeSettingsFromQuoted \
		"$targetBuildSettings" )
	targetSanitizeSettings=""
	targetSanitizePaths=""
	compiledAny=0

	[ -d "$objRoot" ] || mkdir -p "$objRoot"

	printf '\n====== Building Target %s ======\n\n' "$target"
	printf 'Using Build Style: %s\n\n' "$targetStyleName"

		if [ -d "$srcRoot" ]
		then
			srcRoot=${srcRoot%/}

			compileSpacing=0
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
			_bt_work_dir=""
			_bt_file_flags=""

			if depFileIsOutdated "$depPath"
			then
				if [ "$fileFlagsReady" -eq 0 ]
				then
					_prepareFlags "$projectRoot" \
						"$srcDir" \
						"$targetBuildSettings" \
						"$buildSanitizeSettings" \
						"$targetSanitizeSettings" \
						"$targetSanitizePaths" \
						_bt_work_dir _bt_file_flags \
						targetSanitizeSettings \
						targetSanitizePaths
					fileFlagsReady=1
				fi
				generateDepFile "$srcPath" "$depPath" \
					"$_bt_work_dir" "$_bt_file_flags"
			fi

			# Object file older than dep file?
			if isOutdated "$objPath" "$depPath"
			then
				if [ "$fileFlagsReady" -eq 0 ]
				then
					_prepareFlags "$projectRoot" \
						"$srcDir" \
						"$targetBuildSettings" \
						"$buildSanitizeSettings" \
						"$targetSanitizeSettings" \
						"$targetSanitizePaths" \
						_bt_work_dir _bt_file_flags \
						targetSanitizeSettings \
						targetSanitizePaths
					fileFlagsReady=1
				fi
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_bt_had_output=0
				_buildFileWithOutput "$projectRoot" \
					"$srcPath" \
					"$objPath" "$_bt_work_dir" \
					"$_bt_file_flags" \
					_bt_had_output
				compileSpacing=$_bt_had_output
				compiledAny=1
				continue
			fi

				# Check if any dependency has been updated
				# or is missing.
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
				if [ "$fileFlagsReady" -eq 0 ]
				then
					_prepareFlags "$projectRoot" \
						"$srcDir" \
						"$targetBuildSettings" \
						"$buildSanitizeSettings" \
						"$targetSanitizeSettings" \
						"$targetSanitizePaths" \
						_bt_work_dir _bt_file_flags \
						targetSanitizeSettings \
						targetSanitizePaths
					fileFlagsReady=1
				fi
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_bt_had_output=0
				_buildFileWithOutput "$projectRoot" \
					"$srcPath" \
					"$objPath" "$_bt_work_dir" \
					"$_bt_file_flags" \
					_bt_had_output
				compileSpacing=$_bt_had_output
				compiledAny=1
				continue
			fi

			if isOutdated "$objPath" "$@"
			then
				if [ "$fileFlagsReady" -eq 0 ]
				then
					_prepareFlags "$projectRoot" \
						"$srcDir" \
						"$targetBuildSettings" \
						"$buildSanitizeSettings" \
						"$targetSanitizeSettings" \
						"$targetSanitizePaths" \
						_bt_work_dir _bt_file_flags \
						targetSanitizeSettings \
						targetSanitizePaths
					fileFlagsReady=1
				fi
				if [ "$compileSpacing" -eq 1 ]
				then
					printf '\n'
				fi
				printf 'Compiling %s...\n' "$relPath"
				_bt_had_output=0
				_buildFileWithOutput "$projectRoot" \
					"$srcPath" \
					"$objPath" "$_bt_work_dir" \
					"$_bt_file_flags" \
					_bt_had_output
				compileSpacing=$_bt_had_output
				compiledAny=1
			fi
			done <<EOF
$( find "$srcRoot" -type f -name '*.c' )
EOF
		fi

	buildTargetOutput "$projectRoot" "$target" \
		"$targetStyleName" "$buildDir" \
		"$targetBuildSettings" \
		"$targetSanitizeSettings" "$compiledAny"

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
	workDir=$2
	flags=$3
	shift 3

	assert "[ -n \"${outPath:-}\" ]" \
		"createStaticLibrary() missing output path"
	assert "[ -n \"${workDir:-}\" ]" \
		"createStaticLibrary() missing work dir"
	assert "[ -n \"${flags:-}\" ]" "createStaticLibrary() missing flags"
	assert "[ $# -gt 0 ]" "createStaticLibrary() missing object files"

	prelinkPath=$outPath.prelink.o
	prelinkObjects "$prelinkPath" "$workDir" "$flags" "$@"
	createStaticLibraryFromObjects "$outPath" "$workDir" "$prelinkPath"
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
# $7 - 1 if any source was compiled in buildTarget(), otherwise 0.
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
	compiledAny=${7:-0}

	assert "[ -n \"${projectRoot:-}\" ]" \
		"buildTargetOutput() missing project dir"
	assert "[ -n \"${target:-}\" ]" "buildTargetOutput() missing target"
	assert "[ -n \"${targetStyleName:-}\" ]" \
		"buildTargetOutput() missing style name"
	assert "[ -n \"${buildDir:-}\" ]" \
		"buildTargetOutput() missing build dir"

	targetDir=$( buildTargetDirPath "$buildDir" \
		"$targetStyleName" "$target" )
	objDir=$( buildTargetObjDirPath "$buildDir" \
		"$targetStyleName" "$target" )
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
	sanitizeFlags=$( _linkSanitizeFlagsFromSettings \
		"$targetBuildSettings" \
		"$targetSanitizeSettings" )
	if [ -n "$sanitizeFlags" ]
	then
		baseLinkFlags=$( appendQuotedSettings \
			"$baseLinkFlags" \
			"$sanitizeFlags" )
	fi
	finalLinkFlags=$baseLinkFlags
	if [ -n "${__style_set_DEPLOY_PROCESSING+x}" ]
	then
		postFlags=$( _deployPostprocessFlags )
		if [ -n "$postFlags" ]
		then
			postFlagsQuoted=$( quoteSettings "$postFlags" )
			finalLinkFlags=$( appendQuotedSettings \
				"$finalLinkFlags" \
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
			dynamicPath=$targetDir/${target%.lib}$( \
				_dynamicLibExtension )

			if isOutdated "$prelinkPath" "$@"
			then
			if [ "${compiledAny:-0}" -eq 1 ] \
				&& [ "$majorSpacingDone" -eq 0 ]
			then
				printf '\n'
				majorSpacingDone=1
			fi
			printf 'Pre-Linking %s...\n' \
				"${prelinkPath##*/}"
			prelinkFlags="--"
			prelinkObjects "$prelinkPath" "$projectRoot" \
				"$prelinkFlags" "$@"
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
			printf 'Creating archive %s...\n' \
				"${staticPath##*/}"
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
			printf 'Linking %s...\n' \
				"${dynamicPath##*/}"
				linkDynamicLibrary "$dynamicPath" \
					"$projectRoot" "$finalLinkFlags" \
					"$prelinkPath"
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
			linkBinary "$binPath" "$projectRoot" \
				"$finalLinkFlags" "$@"
				printf '\n'
			fi
			;;

		*)
			printErrorAndExit "Unknown target type: $target"
			;;
	esac
)
