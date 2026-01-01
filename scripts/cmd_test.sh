#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


. lib_test.sh


# Prints command usage information.
#
printHelp( )
{
	helpText="
  test [-s[tyle] <style>] [<target>[/suite[/...][/test]] ...]

      Build targets (test style by default), build tests, and run them.
      If no target is provided, all targets are tested.
      You can scope to a suite or a specific test using a pseudo path,
      omitting .ut/.it for specific tests.
"
	printf '%s' "$helpText"
}


# Prints command usage to stderr and exits with failure.
#
printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;
esac

styleName=test

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

styleFile=$styleName
case "$styleFile" in
	/*) ;;
	*/*.cfg|*/*) styleFile="$projDir/$styleFile" ;;
	*.cfg) styleFile="$projDir/styles/$styleFile" ;;
	*) styleFile="$projDir/styles/$styleName.cfg" ;;
esac

if [ ! -f "$styleFile" ]
then
	printErrorAndExit "Style not found: $styleFile"
fi

buildSettings=$( resolvedBuildSettings "$styleFile" )
syncStyleSetVars "$styleFile"

selections=""
if [ "$#" -eq 0 ]
then
	for targetDir in "$projDir"/targets/*
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

		target=$( resolveTargetName "$projDir" "$targetPart" )

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
	collectTestDirs "$projDir" "$target" "$selection" > "$tmpPath"

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

case "$origDir" in
	"$projDir"/*|"$projDir") buildDir=$( outRootPath "$projDir" ) ;;
	*) buildDir="$origDir" ;;
esac

builtTargets=""
printedTargets=""

while IFS= read -r testLine || [ -n "$testLine" ]
do
	[ -n "$testLine" ] || continue
	target=${testLine%%|*}
	testRel=${testLine#*|}
	if [ "$testRel" = "$testLine" ]
	then
		continue
	fi

	case "$testRel" in
		*.ut) testType=ut ;;
		*.it) testType=it ;;
		*) printErrorAndExit "Invalid test name: $target/$testRel" ;;
	esac

	case "$target" in
		*.lib) targetType=lib ;;
		*.bin) targetType=bin ;;
		*) printErrorAndExit "Unknown target type: $target" ;;
	esac

	case "
$builtTargets
" in
		*"
$target
"*) ;;
		*)
			buildTarget "$projDir" "$target" "$styleName" "$buildDir" \
				"$buildSettings"
			builtTargets="$builtTargets
$target"
			;;
	esac

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

	testsRoot=$projDir/targets/$target/tests
	testDir=$testsRoot/$testRel
	[ -d "$testDir" ] \
		|| printErrorAndExit "Test not found: $target/$testRel"

	printf '-- %s\n' "$testRel"

	if [ "$testType" = "it" ] && [ "$targetType" = "bin" ]
	then
		if find "$testDir" -type f -name '*.c' -print -quit \
			| grep -q .
		then
			printErrorAndExit \
				"Integration test must be scripts only: $target/$testRel"
		fi

		targetDir=$( buildTargetDirPath "$buildDir" "$styleName" "$target" )
		binPath=$targetDir/$target
		[ -x "$binPath" ] \
			|| printErrorAndExit "Binary not found: $binPath"

		printf 'Running integration scripts...\n'
		runIntegrationScripts "$testDir" "$binPath" "$target/$testRel"
		printf '\n'
		continue
	fi

	testObjRoot=$( testsTargetObjDirPath "$buildDir" "$styleName" "$target" )
	testOutDir=$( testsTargetBinDirPath "$buildDir" "$styleName" "$target" )
	ensure_dir "$testObjRoot"
	ensure_dir "$testOutDir"

	if ! buildTestObjects "$projDir" "$testsRoot" "$testRel" \
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
	if [ -n "${testSanitizeSettings:-}" ]
	then
		sanitizeFlags=$( quoteSettings "$testSanitizeSettings" )
		linkFlags=$( appendQuotedSettings "$linkFlags" "$sanitizeFlags" )
	fi
	[ -n "$linkFlags" ] || linkFlags="--"

	testBinPath=$( testBinaryPath "$testOutDir" "$testRel" )
	case "$testBinPath" in
		*/*) ensure_dir "${testBinPath%/*}" ;;
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
		linkBinary "$testBinPath" "$projDir" "$linkFlags" "$@"
		printf 'Running %s...\n' "${testBinPath##*/}"
		runTestBinary "$testBinPath"
		printf '\n'
		continue
	fi

	if [ "$testType" = "it" ] && [ "$targetType" = "lib" ]
	then
		targetDir=$( buildTargetDirPath "$buildDir" "$styleName" "$target" )
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
		linkBinary "$testBinPath" "$projDir" "$linkFlags" "$@"
		printf 'Running %s...\n' "${testBinPath##*/}"
		runTestBinary "$testBinPath" "$targetDir"
		printf '\n'
		continue
	fi

	printErrorAndExit "Unsupported test type: $target/$testRel"
done <<EOF
$testsToRun
EOF

printf '\n====== All Done ======\n'
