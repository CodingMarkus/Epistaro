#!/bin/sh

set -eu

[ -n "${__included_lib_build_sh:-}" ] && return 0
__included_lib_build_sh=1


. lib_ar.sh
. lib_build_common.sh
. lib_build_settings.sh
. lib_clang.sh
. lib_clean.sh
. lib_link.sh
. lib_outdated.sh
. lib_paths.sh


# $1 - Project root directory.
# $2 - Target name.
# $3 - Style name.
# $4 - Build output root directory.
# ($5) - Optional target output directory override.
#
# Copies public headers for library targets into the build include dir.
#
_syncPublicHeaders( )
(
	projectRoot=$1
	target=$2
	targetStyleName=$3
	buildDir=$4
	targetOutDir=${5:-}

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
		"$targetStyleName" "$target" "$targetOutDir" )

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
# ($6) - Optional target output directory override.
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
	targetOutDir=${6:-}

assert "[ -n \"${projectRoot:-}\" ]" \
	"buildTarget() missing project dir"

	targetDir=$projectRoot/targets/$target
	srcRoot=$targetDir/src
	objRoot=$( buildTargetObjSrcDirPath "$buildDir" \
		"$targetStyleName" "$target" "$targetOutDir" )

	buildSanitizeSettings=$( sanitizeSettingsFromQuoted \
		"$targetBuildSettings" )
	targetSanitizeSettings=""
	targetSanitizePaths=""
	compiledAny=0

	[ -d "$objRoot" ] || mkdir -p "$objRoot"

	pruneObjectTree "$srcRoot" "$objRoot"
	purgeOutdatedDepsByStyle "$projectRoot" "$objRoot"

	targetLabel=$( formatTargetLabel "$target" )
	printHeader "====== Building Target $targetLabel ======"
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
					prepareFlags "$projectRoot" \
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
				updateDepFileIfOutdated "$srcPath" "$depPath" \
					"$_bt_work_dir" "$_bt_file_flags"
			fi

			assertDepFileNotEmpty "$depPath"

			# Object file older than dep file?
			if isOutdated "$objPath" "$depPath"
			then
				if [ "$fileFlagsReady" -eq 0 ]
				then
					prepareFlags "$projectRoot" \
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
				buildFileWithOutput "$projectRoot" \
					"$srcPath" \
					"$objPath" "$_bt_work_dir" \
					"$_bt_file_flags" \
					_bt_had_output
				compileSpacing=$_bt_had_output
				compiledAny=1
				continue
			fi

			done <<EOF
$( find "$srcRoot" -type f -name '*.c' )
EOF
		fi

	_buildTargetOutput "$projectRoot" "$target" \
		"$targetStyleName" "$buildDir" \
		"$targetBuildSettings" \
		"$targetSanitizeSettings" "$compiledAny" \
		"$targetOutDir"

	case "$target" in
		*.lib)
			printf 'Copying Public Headers...\n'
			_syncPublicHeaders "$projectRoot" "$target" \
				"$targetStyleName" "$buildDir" "$targetOutDir"
			printf '\n'
			;;
	esac

	printf 'Done.\n'
)


# $1 - Project root directory.
# $2 - Target name.
# $3 - Style name.
# $4 - Build output root directory.
# $5 - Quoted build settings string.
# $6 - Sanitizer settings string containing one entry per line.
# $7 - 1 if any source was compiled in buildTarget(), otherwise 0.
# ($8) - Optional target output directory override.
#
# Links final target outputs based on target name extension.
#
_buildTargetOutput( )
(
	projectRoot=$1
	target=$2
	targetStyleName=$3
	buildDir=$4
	targetBuildSettings=$5
	targetSanitizeSettings=$6
	compiledAny=${7:-0}
	targetOutDir=${8:-}

	assert "[ -n \"${projectRoot:-}\" ]" \
		"_buildTargetOutput() missing project dir"
	assert "[ -n \"${target:-}\" ]" "_buildTargetOutput() missing target"
	assert "[ -n \"${targetStyleName:-}\" ]" \
		"_buildTargetOutput() missing style name"
	assert "[ -n \"${buildDir:-}\" ]" \
		"_buildTargetOutput() missing build dir"

	targetDir=$( buildTargetDirPath "$buildDir" \
		"$targetStyleName" "$target" "$targetOutDir" )
	objDir=$( buildTargetObjDirPath "$buildDir" \
		"$targetStyleName" "$target" "$targetOutDir" )
	objSrcRoot=$( buildTargetObjSrcDirPath "$buildDir" \
		"$targetStyleName" "$target" "$targetOutDir" )

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

	majorSpacingDone=0
	finalLinkFlags=$( linkFlagsFromSettings \
		"$targetBuildSettings" "$targetSanitizeSettings" )

	case "$target" in
		*.lib)
			staticPath=$targetDir/${target%.*}.a
			dynamicPath=$targetDir/${target%.lib}$( \
				dynamicLibExtension )

			if isOutdated "$staticPath" "$@"
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
					"$projectRoot" "$@"
				printf '\n'
			fi

			_dynamic_spacing=0
			if [ "${compiledAny:-0}" -eq 1 ] \
				&& [ "$majorSpacingDone" -eq 0 ]
			then
				_dynamic_spacing=1
			fi
			linkDynamicLibraryFinal "$dynamicPath" "$projectRoot" \
				"$finalLinkFlags" "$_dynamic_spacing" 0 \
				"$@"
			;;

		*.bin)
			binPath=$targetDir/$target
			_bin_spacing=0
			if [ "${compiledAny:-0}" -eq 1 ] \
				&& [ "$majorSpacingDone" -eq 0 ]
			then
				_bin_spacing=1
			fi
			linkBinaryFinal "$binPath" "$projectRoot" \
				"$finalLinkFlags" "$_bin_spacing" 0 "$@"
			;;

		*)
			printErrorAndExit "Unknown target type: $target"
			;;
	esac
)
