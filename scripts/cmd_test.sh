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
# Sets test parsing globals: _pt_target, _pt_rel, _pt_test_type,
# _pt_target_type
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
		*)
			printErrorAndExit \
				"Invalid test name: $_pt_target/$_pt_rel"
			;;
	esac

	case "$_pt_target" in
		*.lib) _pt_target_type=lib ;;
		*.bin) _pt_target_type=bin ;;
		*) printErrorAndExit "Unknown target type: $_pt_target" ;;
	esac
}

# $1 - Test binary path.
# $2 - Test label.
# ($3) - Optional dynamic library directory.
#
# Runs a test binary and prints status, emitting captured stderr on failure.
#
runTestAndReport( )
{
	_rtr_path=$1
	_rtr_label=$2
	_rtr_lib=${3:-}

	_rtr_err=$( mktemp "${TMPDIR:-/tmp}/test.err.XXXXXX" ) \
		|| printErrorAndExit "mktemp failed"

	if [ -n "$_rtr_lib" ]
	then
		if runTestBinary "$_rtr_path" "$_rtr_lib" 2>"$_rtr_err"
		then
			printf 'Testing %s... [PASSED]\n' "$_rtr_label"
			rm -f "$_rtr_err"
			return 0
		fi
	else
		if runTestBinary "$_rtr_path" 2>"$_rtr_err"
		then
			printf 'Testing %s... [PASSED]\n' "$_rtr_label"
			rm -f "$_rtr_err"
			return 0
		fi
	fi

	_rtr_status=$?
	printf 'Testing %s... [FAILED]\n' "$_rtr_label"
	if [ -s "$_rtr_err" ]
	then
		cat "$_rtr_err"
	fi
	rm -f "$_rtr_err"
	return "$_rtr_status"
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
				[ -n "$selection" ] || printErrorAndExit \
					"Invalid test path: $spec"
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
targetsToRun=$( printf '%s\n' "$testsToRun" \
	| awk -F'|' 'NF && !seen[$1]++ { print $1 }' )

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

	while IFS= read -r target || [ -n "$target" ]
	do
		[ -n "$target" ] || continue
		buildTarget "$__projDir" "$target" \
			"$styleName" "$buildDir" \
			"$buildSettings"
	done <<EOF
$targetsToRun
EOF

	while IFS= read -r target || [ -n "$target" ]
	do
		[ -n "$target" ] || continue
		printf '\n%s\n\n' "====== Building Tests for Target $target ======"
		printf 'Using Build Style: %s\n\n' "$styleName"
		targetHadOutput=0
		testSpacingPending=0

		while IFS= read -r testLine || [ -n "$testLine" ]
		do
			[ -n "$testLine" ] || continue
			parseTestLine "$testLine"
			[ "$_pt_target" = "$target" ] || continue
			testRel=$_pt_rel
			testType=$_pt_test_type
			targetType=$_pt_target_type

			testsRoot=$__projDir/targets/$target/tests
			testDir=$testsRoot/$testRel
			[ -d "$testDir" ] || printErrorAndExit \
				"Test not found: $target/$testRel"

			if [ "$testType" = "it" ] && [ "$targetType" = "bin" ]
			then
				if find "$testDir" -type f -name '*.c' \
					-print -quit | grep -q .
				then
					_err_msg="Integration test must be "
					_err_msg="${_err_msg}scripts only: $target/$testRel"
					printErrorAndExit "$_err_msg"
				fi
				continue
			fi

			testObjRoot=$( testsTargetObjDirPath "$buildDir" \
				"$styleName" "$target" )
			testOutDir=$( testsTargetBinDirPath "$buildDir" \
				"$styleName" "$target" )
			ensureDir "$testObjRoot"
			ensureDir "$testOutDir"

			testSanitizeSettings=""
			testCompiled=0
			testName=${testRel%.*}
			testLabel="$testName [$testType]"
			preHeaderSpacing=0
			if [ "$testSpacingPending" -eq 1 ]
			then
				preHeaderSpacing=2
			fi
			if ! buildTestObjects "$__projDir" "$testsRoot" \
				"$testRel" "$testObjRoot" "$buildSettings" \
				testSanitizeSettings testCompiled "$testLabel" \
				"$preHeaderSpacing"
			then
				if [ "$?" -eq 2 ]
				then
						_err_msg="No C sources found for "
						_err_msg="${_err_msg}test: $target/$testRel"
						printErrorAndExit "$_err_msg"
				fi
				exit 1
			fi
			if [ "$testCompiled" -eq 1 ]
			then
				targetHadOutput=1
				testSpacingPending=1
			fi

			testObjs=$( collectTestObjects "$testObjRoot" "$testRel" )
			[ -n "$testObjs" ] \
				|| printErrorAndExit \
					"No objects found for test: $target/$testRel"

			linkFlags=$( _linkFlagsFromSettings \
				"$buildSettings" "$testSanitizeSettings" )

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

				targetObjs=$( collectTargetObjects "$buildDir" \
					"$styleName" "$target" "$excludeMain" )
				[ -n "$targetObjs" ] \
					|| printErrorAndExit \
						"No target objects for $target"

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

				if isOutdated "$testBinPath" "$@"
				then
					if [ "$testCompiled" -eq 1 ]
					then
						printf '\n'
					fi
					testBinName=${testBinPath##*/}
					printf 'Linking %s [%s]...\n' \
						"$testBinName" "$testType"
					linkBinary "$testBinPath" "$__projDir" \
						"$linkFlags" "$@"
					targetHadOutput=1
					testSpacingPending=1
				fi
				continue
			fi

			if [ "$testType" = "it" ] && [ "$targetType" = "lib" ]
			then
				targetDir=$( buildTargetDirPath "$buildDir" \
					"$styleName" "$target" )
				dynamicPath=$targetDir/${target%.lib}$( \
					_dynamicLibExtension )
				[ -f "$dynamicPath" ] \
					|| printErrorAndExit \
						"Library not found: $dynamicPath"

				set --
				while IFS= read -r objPath || [ -n "$objPath" ]
				do
					[ -n "$objPath" ] || continue
					set -- "$@" "$objPath"
				done <<EOF
$testObjs
EOF
				set -- "$@" "$dynamicPath"

				if isOutdated "$testBinPath" "$@"
				then
					if [ "$testCompiled" -eq 1 ]
					then
						printf '\n'
					fi
					testBinName=${testBinPath##*/}
					printf 'Linking %s [%s]...\n' \
						"$testBinName" "$testType"
					linkBinary "$testBinPath" "$__projDir" \
						"$linkFlags" "$@"
					targetHadOutput=1
					testSpacingPending=1
				fi
				continue
			fi

			printErrorAndExit \
				"Unsupported test type: $target/$testRel"
		done <<EOF
$testsToRun
EOF
		if [ "$targetHadOutput" -eq 1 ]
		then
			printf '\n'
		fi
		printf 'Done.\n'
	done <<EOF
$targetsToRun
EOF
done <<EOF
$styleNames
EOF

while IFS= read -r styleName || [ -n "$styleName" ]
do
	[ -n "$styleName" ] || continue

	styleFile=$( resolveStyleFile "$styleName" )
	syncStyleSetVars "$styleFile"

	if [ "$multipleStyles" -eq 1 ]
	then
		printf '\n====== Testing Style %s ======\n\n' "$styleName"
	fi

	while IFS= read -r target || [ -n "$target" ]
	do
		[ -n "$target" ] || continue
		printf '\n%s\n\n' "====== Running Tests for Target $target ======"

		while IFS= read -r testLine || [ -n "$testLine" ]
		do
			[ -n "$testLine" ] || continue
			parseTestLine "$testLine"
			[ "$_pt_target" = "$target" ] || continue
			testRel=$_pt_rel
			testType=$_pt_test_type
			targetType=$_pt_target_type

			testsRoot=$__projDir/targets/$target/tests
			testDir=$testsRoot/$testRel
			[ -d "$testDir" ] || printErrorAndExit \
				"Test not found: $target/$testRel"

			if [ "$testType" = "it" ] && [ "$targetType" = "bin" ]
			then
				targetDir=$( buildTargetDirPath "$buildDir" \
					"$styleName" "$target" )
				binPath=$targetDir/$target
				[ -x "$binPath" ] || printErrorAndExit \
					"Binary not found: $binPath"

				printf 'Running integration scripts...\n'
				runIntegrationScripts "$testDir" "$binPath" \
					"$target/$testRel"
				printf '\n'
				continue
			fi

			testOutDir=$( testsTargetBinDirPath "$buildDir" \
				"$styleName" "$target" )
			testBinPath=$( testBinaryPath "$testOutDir" "$testRel" )
			testName=${testBinPath##*/}

			if [ "$testType" = "ut" ]
			then
				runTestAndReport "$testBinPath" "$testName"
				printf '\n'
				continue
			fi

			if [ "$testType" = "it" ] && [ "$targetType" = "lib" ]
			then
				targetDir=$( buildTargetDirPath "$buildDir" \
					"$styleName" "$target" )
				dynamicPath=$targetDir/${target%.lib}$( \
					_dynamicLibExtension )
				[ -f "$dynamicPath" ] \
					|| printErrorAndExit \
						"Library not found: $dynamicPath"

				runTestAndReport "$testBinPath" "$testName" \
					"$targetDir"
				printf '\n'
				continue
			fi

			printErrorAndExit \
				"Unsupported test type: $target/$testRel"
		done <<EOF
$testsToRun
EOF
		printf 'Done.\n'
	done <<EOF
$targetsToRun
EOF
done <<EOF
$styleNames
EOF

printf '\n====== All Done ======\n'
