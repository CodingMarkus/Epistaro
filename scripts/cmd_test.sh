#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_test.sh


# Prints command usage information.
#
printHelp( )
{
	_ph_text="
  test [[-s[tyle] <style>] ...] [<target>[/suite[/...][/test]] ...]

      Build targets (test style by default), build tests, and run them.
      Repeat -style to test multiple styles in a single run.
      If no target is provided, all targets are tested.
      You can scope to a suite or a specific test using a pseudo path,
      omitting .ut/.it for specific tests.
"
	printf '%s' "$_ph_text"
}


# Prints command usage to stderr and exits with failure.
#
printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


# $1 - Style name.
#
# Appends the style name to the style list.
#
appendStyleName( )
{
	_asn_style=$1

	if [ -n "$styleNames" ]
	then
		styleNames="$styleNames
$_asn_style"
	else
		styleNames=$_asn_style
	fi
}


# $1 - Style name.
#
# Resolves a style file path and ensures it exists.
#
resolveStyleFile( )
{
	_rsf_style=$1
	_rsf_file=$_rsf_style
	case "$_rsf_file" in
		/*) ;;
		*/*.cfg|*/*) _rsf_file="$__projDir/$_rsf_file" ;;
		*.cfg) _rsf_file="$__projDir/styles/$_rsf_file" ;;
		*) _rsf_file="$__projDir/styles/$_rsf_style.cfg" ;;
	esac

	if [ ! -f "$_rsf_file" ]
	then
		printErrorAndExit "Style not found: $_rsf_file"
	fi

	printf '%s\n' "$_rsf_file"
}


# $1 - Test line (target|test path).
#
# Sets test parsing globals: _pt_target, _pt_rel, _pt_test_type, _pt_target_type
#
parseTestLine( )
{
	_pt_line=$1
	_pt_target=${_pt_line%%|*}
	_pt_rel=${_pt_line#*|}
	if [ "$_pt_rel" = "$_pt_line" ]
	then
		printErrorAndExit "Invalid test selection: $_pt_line"
	fi

	case "$_pt_rel" in
		*.ut) _pt_test_type=ut ;;
		*.it) _pt_test_type=it ;;
		*) printErrorAndExit "Invalid test name: $_pt_target/$_pt_rel" ;;
	esac

	case "$_pt_target" in
		*.lib) _pt_target_type=lib ;;
		*.bin) _pt_target_type=bin ;;
		*) printErrorAndExit "Unknown target type: $_pt_target" ;;
	esac
}


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;
esac

styleName="test"
styleNames=""

while [ "$#" -gt 0 ]
do
	case "$1" in
		--help)
			printHelp
			exit 0
			;;

		-*)
			if isStyleFlag "$1"
			then
				shift
				[ "$#" -gt 0 ] || printHelpAndExit
				styleName=$1
				ensureValidStyleName "$styleName"
				appendStyleName "$styleName"
				shift
				continue
			fi
			printHelpAndExit
			;;

		*)
			break
			;;
	esac
done
if [ -z "$styleNames" ]
then
	styleNames=$styleName
fi

platformRequireSupportedTarget

selections=""
if [ "$#" -eq 0 ]
then
	for targetDir in "$__projDir"/targets/*
	do
		[ -d "$targetDir" ] || continue
		target=$( basename -- "$targetDir" )
		if [ -n "$selections" ]
		then
			selections="$selections
$target|"
		else
			selections="$target|"
		fi
	done
	if [ -z "$selections" ]
	then
		printErrorAndExit "No targets found"
	fi
else
	for spec in "$@"
	do
		case "$spec" in
			*/*)
				targetPart=${spec%%/*}
				selection=${spec#*/}
				[ -n "$selection" ] \
					|| printErrorAndExit "Invalid test path: $spec"
				;;
			*)
				targetPart=$spec
				selection=
				;;
		esac

		target=$( resolveTargetName "$__projDir" "$targetPart" )

		if [ -n "$selections" ]
		then
			selections="$selections
$target|$selection"
		else
			selections="$target|$selection"
		fi
	done
fi

testsToRun=""

tmpPath=$( mktemp "${TMPDIR:-/tmp}/tests.XXXXXX" ) \
	|| printErrorAndExit "mktemp failed"

while IFS= read -r selectionLine || [ -n "$selectionLine" ]
do
	[ -n "$selectionLine" ] || continue
	target=${selectionLine%%|*}
	selection=${selectionLine#*|}
	if [ "$selection" = "$selectionLine" ]
	then
		selection=
	fi

	: > "$tmpPath"
	collectTestDirs "$__projDir" "$target" "$selection" > "$tmpPath"

	if [ ! -s "$tmpPath" ]
	then
		if [ -n "$selection" ]
		then
			printErrorAndExit \
				"No tests found for $target/$selection"
		fi
		continue
	fi

	while IFS= read -r testRel || [ -n "$testRel" ]
	do
		[ -n "$testRel" ] || continue
		entry=$target\|$testRel
		if [ -n "$testsToRun" ]
		then
			testsToRun="$testsToRun
$entry"
		else
			testsToRun=$entry
		fi
	done < "$tmpPath"
done <<EOF
$selections
EOF

rm -f "$tmpPath"

testsToRun=$( printf '%s\n' "$testsToRun" | awk 'NF && !seen[$0]++' )

if [ -z "$testsToRun" ]
then
	printf '\nNo tests found.\n'
	exit 0
fi

case "$__origDir" in
	"$__projDir"/*|"$__projDir") buildDir=$( outRootPath "$__projDir" ) ;;
	*) buildDir="$__origDir" ;;
esac

multipleStyles=0
case "$styleNames" in
	*"
"*) multipleStyles=1 ;;
esac

while IFS= read -r styleName || [ -n "$styleName" ]
do
	[ -n "$styleName" ] || continue

	styleFile=$( resolveStyleFile "$styleName" )
	buildSettings=$( resolvedBuildSettings "$styleFile" )
	syncStyleSetVars "$styleFile"

	if [ "$multipleStyles" -eq 1 ]
	then
		printf '\n====== Building Style %s ======\n\n' "$styleName"
	fi

	builtTargets=""
	while IFS= read -r testLine || [ -n "$testLine" ]
	do
		[ -n "$testLine" ] || continue
		parseTestLine "$testLine"
		target=$_pt_target
		testRel=$_pt_rel
		testType=$_pt_test_type
		targetType=$_pt_target_type

		case "
$builtTargets
" in
			*"
$target
"*) ;;
			*)
				buildTarget "$__projDir" "$target" "$styleName" "$buildDir" \
					"$buildSettings"
				builtTargets="$builtTargets
$target"
				;;
		esac

		testsRoot=$__projDir/targets/$target/tests
		testDir=$testsRoot/$testRel
		[ -d "$testDir" ] \
			|| printErrorAndExit "Test not found: $target/$testRel"

		if [ "$testType" = "it" ] && [ "$targetType" = "bin" ]
		then
			if find "$testDir" -type f -name '*.c' -print -quit \
				| grep -q .
			then
				printErrorAndExit \
					"Integration test must be scripts only: $target/$testRel"
			fi
			continue
		fi

		testObjRoot=$( testsTargetObjDirPath "$buildDir" "$styleName" \
			"$target" )
		testOutDir=$( testsTargetBinDirPath "$buildDir" "$styleName" \
			"$target" )
		ensureDir "$testObjRoot"
		ensureDir "$testOutDir"

		if ! buildTestObjects "$__projDir" "$testsRoot" "$testRel" \
			"$testObjRoot" "$buildSettings"
		then
			if [ "$?" -eq 2 ]
			then
				printErrorAndExit \
					"No C sources found for test: $target/$testRel"
			fi
			exit 1
		fi

		testObjs=$( collectTestObjects "$testObjRoot" "$testRel" )
		[ -n "$testObjs" ] \
			|| printErrorAndExit "No objects found for test: $target/$testRel"

		linkFlags=$buildSettings
		if [ -n "${__testSanitizeSettings:-}" ]
		then
			sanitizeFlags=$( quoteSettings "$__testSanitizeSettings" )
			linkFlags=$( appendQuotedSettings "$linkFlags" "$sanitizeFlags" )
		fi
		[ -n "$linkFlags" ] || linkFlags="--"

		testBinPath=$( testBinaryPath "$testOutDir" "$testRel" )
		case "$testBinPath" in
			*/*) ensureDir "${testBinPath%/*}" ;;
		esac

		if [ "$testType" = "ut" ]
		then
			excludeMain=0
			if [ "$targetType" = "bin" ]
			then
				excludeMain=1
			fi

			targetObjs=$( collectTargetObjects "$buildDir" "$styleName" \
				"$target" "$excludeMain" )
			[ -n "$targetObjs" ] \
				|| printErrorAndExit "No target objects for $target"

			set --
			while IFS= read -r objPath || [ -n "$objPath" ]
			do
				[ -n "$objPath" ] || continue
				set -- "$@" "$objPath"
			done <<EOF
$targetObjs
EOF
			while IFS= read -r objPath || [ -n "$objPath" ]
			do
				[ -n "$objPath" ] || continue
				set -- "$@" "$objPath"
			done <<EOF
$testObjs
EOF

			printf 'Linking %s...\n' "${testBinPath##*/}"
			linkBinary "$testBinPath" "$__projDir" "$linkFlags" "$@"
			continue
		fi

		if [ "$testType" = "it" ] && [ "$targetType" = "lib" ]
		then
			targetDir=$( buildTargetDirPath "$buildDir" "$styleName" \
				"$target" )
			dynamicPath=$targetDir/${target%.lib}$( _dynamicLibExtension )
			[ -f "$dynamicPath" ] \
				|| printErrorAndExit "Library not found: $dynamicPath"

			set --
			while IFS= read -r objPath || [ -n "$objPath" ]
			do
				[ -n "$objPath" ] || continue
				set -- "$@" "$objPath"
			done <<EOF
$testObjs
EOF
			set -- "$@" "$dynamicPath"

			printf 'Linking %s...\n' "${testBinPath##*/}"
			linkBinary "$testBinPath" "$__projDir" "$linkFlags" "$@"
			continue
		fi

		printErrorAndExit "Unsupported test type: $target/$testRel"
	done <<EOF
$testsToRun
EOF
done <<EOF
$styleNames
EOF

while IFS= read -r styleName || [ -n "$styleName" ]
do
	[ -n "$styleName" ] || continue

	styleFile=$( resolveStyleFile "$styleName" )
	syncStyleSetVars "$styleFile"

	printedTargets=""

	if [ "$multipleStyles" -eq 1 ]
	then
		printf '\n====== Testing Style %s ======\n\n' "$styleName"
	fi

	while IFS= read -r testLine || [ -n "$testLine" ]
	do
		[ -n "$testLine" ] || continue
		parseTestLine "$testLine"
		target=$_pt_target
		testRel=$_pt_rel
		testType=$_pt_test_type
		targetType=$_pt_target_type

		case "
$printedTargets
" in
			*"
$target
"*) ;;
			*)
				printf '\n====== Testing Target %s ======\n\n' "$target"
				printedTargets="$printedTargets
$target"
				;;
		esac

		testsRoot=$__projDir/targets/$target/tests
		testDir=$testsRoot/$testRel
		[ -d "$testDir" ] \
			|| printErrorAndExit "Test not found: $target/$testRel"

		printf '%s\n' "-- $testRel"

		if [ "$testType" = "it" ] && [ "$targetType" = "bin" ]
		then
			targetDir=$( buildTargetDirPath "$buildDir" "$styleName" \
				"$target" )
			binPath=$targetDir/$target
			[ -x "$binPath" ] \
				|| printErrorAndExit "Binary not found: $binPath"

			printf 'Running integration scripts...\n'
			runIntegrationScripts "$testDir" "$binPath" "$target/$testRel"
			printf '\n'
			continue
		fi

		testOutDir=$( testsTargetBinDirPath "$buildDir" "$styleName" \
			"$target" )
		testBinPath=$( testBinaryPath "$testOutDir" "$testRel" )

		if [ "$testType" = "ut" ]
		then
			printf 'Running %s...\n' "${testBinPath##*/}"
			runTestBinary "$testBinPath"
			printf '\n'
			continue
		fi

		if [ "$testType" = "it" ] && [ "$targetType" = "lib" ]
		then
			targetDir=$( buildTargetDirPath "$buildDir" "$styleName" \
				"$target" )
			dynamicPath=$targetDir/${target%.lib}$( _dynamicLibExtension )
			[ -f "$dynamicPath" ] \
				|| printErrorAndExit "Library not found: $dynamicPath"

			printf 'Running %s...\n' "${testBinPath##*/}"
			runTestBinary "$testBinPath" "$targetDir"
			printf '\n'
			continue
		fi

		printErrorAndExit "Unsupported test type: $target/$testRel"
	done <<EOF
$testsToRun
EOF
done <<EOF
$styleNames
EOF

printf '\n====== All Done ======\n'
