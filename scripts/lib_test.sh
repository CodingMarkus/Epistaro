#!/bin/sh

set -eu

[ -n "${__included_lib_test_sh:-}" ] && return 0
__included_lib_test_sh=1


. lib_error.sh
. lib_paths.sh
. lib_build.sh
. lib_fs.sh
. lib_quote.sh
. lib_outdated.sh


# $1 - Argument to test.
#
# Returns success if the argument is a style flag.
#
isStyleFlag( )
{
	case "${1:-}" in
		-s|-st|-sty|-styl|-style) return 0 ;;
		*) return 1 ;;
	esac
}


# $1 - Suite directory path.
#
# Prints test paths within the suite, relative to the tests root.
#
_collectTestsInSuite( )
{
	suiteDir=$1

	testDirs=""
	suiteDirs=""
	while IFS= read -r dir || [ -n "$dir" ]
	do
		[ -n "$dir" ] || continue
		base=${dir##*/}
		case "$base" in
			*.ut|*.it) testDirs="$testDirs
$dir" ;;
			*) suiteDirs="$suiteDirs
$dir" ;;
		esac
	done <<EOF
$( find "$suiteDir" -mindepth 1 -maxdepth 1 -type d -print )
EOF

	if [ -n "$testDirs" ] && [ -n "$suiteDirs" ]
	then
		suiteRel=${suiteDir#"$testsRoot"/}
		if [ -z "$suiteRel" ] || [ "$suiteRel" = "$suiteDir" ]
		then
			suiteRel="tests"
		fi
		printErrorAndExit \
			"Suite contains tests and sub-suites: $suiteRel"
	fi

	if [ -n "$testDirs" ]
	then
		while IFS= read -r testDir || [ -n "$testDir" ]
		do
			[ -n "$testDir" ] || continue
			printf '%s\n' "${testDir#"$testsRoot"/}"
		done <<EOF
$testDirs
EOF
		return 0
	fi

	while IFS= read -r subDir || [ -n "$subDir" ]
	do
		[ -n "$subDir" ] || continue
		_collectTestsInSuite "$subDir"
	done <<EOF
$suiteDirs
EOF
}


# $1 - Project root directory.
# $2 - Target name.
#
# ($3) - Optional test selection path.
# Prints selected test paths relative to the target tests root.
#
collectTestDirs( )
{
	projectRoot=$1
	target=$2
	selection=${3:-}

	testsRoot=$projectRoot/targets/$target/tests
	if [ ! -d "$testsRoot" ]
	then
		if [ -n "$selection" ]
		then
			printErrorAndExit "Tests not found: $target/$selection"
		fi
		return 0
	fi

	testsRoot=$( strip_trailing_slash "$testsRoot" )
	selection=${selection%/}

	case "$selection" in
		""|.) ;;
		/*|*"/../"*|*"/.."|../*|..) \
			printErrorAndExit "Invalid test path: $target/$selection" ;;
	esac

	case "$selection" in
		""|.)
			_collectTestsInSuite "$testsRoot"
			;;

		*.ut|*.it)
			testDir=$testsRoot/$selection
			[ -d "$testDir" ] \
				|| printErrorAndExit "Test not found: $target/$selection"
			printf '%s\n' "$selection"
			;;

		*)
			candidateUt=$testsRoot/$selection.ut
			candidateIt=$testsRoot/$selection.it

			if [ -d "$candidateUt" ] && [ -d "$candidateIt" ]
			then
				printErrorAndExit \
					"Duplicate test name: $target/$selection"
			fi
			if [ -d "$candidateUt" ]
			then
				printf '%s.ut\n' "$selection"
				return 0
			fi
			if [ -d "$candidateIt" ]
			then
				printf '%s.it\n' "$selection"
				return 0
			fi

			suiteDir=$testsRoot/$selection
			[ -d "$suiteDir" ] || printErrorAndExit \
				"Test or suite not found: $target/$selection"
			_collectTestsInSuite "$suiteDir"
			;;
	esac
}


# $1 - Project root directory.
# $2 - Tests root directory.
# $3 - Test path relative to the tests root.
# $4 - Object output root directory.
# $5 - Quoted build settings string.
#
# Builds objects for a test and updates sanitizer settings.
#
buildTestObjects( )
{
	projectRoot=$1
	testsRoot=$2
	testRel=$3
	objRoot=$4
	buildSettings=$5

	testSrcDir=$testsRoot/$testRel
	[ -d "$testSrcDir" ] \
		|| printErrorAndExit "Test source dir not found: $testRel"

	srcList=$( find "$testSrcDir" -type f -name '*.c' -print )
	if [ -z "$srcList" ]
	then
		return 2
	fi

	oldBuildSanitize=${__buildSanitizeSettings:-}
	oldTargetSanitize=${__targetSanitizeSettings:-}
	oldTargetSanitizePaths=${__targetSanitizePaths:-}

	__buildSanitizeSettings=$( _sanitizeSettingsFromQuoted "$buildSettings" )
	__targetSanitizeSettings=""
	__targetSanitizePaths=""

	compileSpacing=0
	compiledAny=0
	while IFS= read -r srcPath || [ -n "$srcPath" ]
	do
		[ -n "$srcPath" ] || continue

		relPath=${srcPath#"$testsRoot"/}
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
			_prepareFlags "$projectRoot" "$srcDir" "$buildSettings"
			generateDepFile "$srcPath" "$depPath" "$__workDir" \
				"$__fileFlags"
		fi

		if isOutdated "$objPath" "$depPath"
		then
			if [ "$compileSpacing" -eq 1 ]
			then
				printf '\n'
			fi
			printf 'Compiling %s...\n' "$relPath"
			_buildFileWithOutput "$projectRoot" "$srcPath" \
				"$objPath" "$srcDir" "$buildSettings"
			compileSpacing=$__buildFileHadOutput
			compiledAny=1
			continue
		fi

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
			_buildFileWithOutput "$projectRoot" "$srcPath" \
				"$objPath" "$srcDir" "$buildSettings"
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
			_buildFileWithOutput "$projectRoot" "$srcPath" \
				"$objPath" "$srcDir" "$buildSettings"
			compileSpacing=$__buildFileHadOutput
			compiledAny=1
		fi
	done <<EOF
$srcList
EOF

	testSanitizeSettings=$__targetSanitizeSettings

	__buildSanitizeSettings=$oldBuildSanitize
	__targetSanitizeSettings=$oldTargetSanitize
	__targetSanitizePaths=$oldTargetSanitizePaths
}


# $1 - Object output root directory.
# $2 - Test path relative to the tests root.
#
# Prints object files for a test, if any.
#
collectTestObjects( )
{
	objRoot=$1
	testRel=$2

	testObjDir=$objRoot/$testRel
	if [ ! -d "$testObjDir" ]
	then
		return 0
	fi

	find "$testObjDir" -type f -name '*.o' -print
}


# $1 - Build output root directory.
# $2 - Style name.
# $3 - Target name.
#
# ($4) - Optional flag to exclude main.o.
# Prints target object files.
#
collectTargetObjects( )
{
	buildDir=$1
	styleName=$2
	target=$3
	excludeMain=${4:-0}

	objRoot=$( buildTargetObjSrcDirPath "$buildDir" "$styleName" "$target" )
	[ -d "$objRoot" ] || return 0

	if [ "$excludeMain" -eq 1 ]
	then
		find "$objRoot" -type f -name '*.o' ! -name 'main.o' -print
	else
		find "$objRoot" -type f -name '*.o' -print
	fi
}


# $1 - Tests target directory path.
# $2 - Test path relative to the tests root.
#
# Prints the path to the test binary.
#
testBinaryPath( )
{
	testsTargetDir=$1
	testRel=$2

	testBase=${testRel##*/}
	testName=${testBase%.*}

	case "$testRel" in
		*/*) printf '%s/%s/%s\n' "$testsTargetDir" \
			"${testRel%/*}" "$testName" ;;
		*) printf '%s/%s\n' "$testsTargetDir" "$testName" ;;
	esac
}


# $1 - Test binary path.
#
# ($2) - Optional dynamic library directory.
# Runs a test binary with optional library path injection.
#
runTestBinary( )
{
	binPath=$1
	libDir=${2:-}

	binDir=${binPath%/*}
	binBase=${binPath##*/}

	if [ -n "$libDir" ]
	then
		(
			cd "$binDir"
			DYLD_LIBRARY_PATH="$libDir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
			LD_LIBRARY_PATH="$libDir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
			"./$binBase"
		)
	else
		(
			cd "$binDir"
			"./$binBase"
		)
	fi
}


# $1 - Test directory path.
# $2 - Test binary path.
# $3 - Test label for error reporting.
#
# Runs integration test scripts for a test directory.
#
runIntegrationScripts( )
{
	testDir=$1
	binPath=$2
	testLabel=$3

	execList=$( find "$testDir" -maxdepth 1 -type f -perm -111 -print )
	if [ -n "$execList" ]
	then
		scriptList=$execList
	else
		scriptList=$( find "$testDir" -maxdepth 1 -type f \
			-name '*.sh' -print )
	fi

	if [ -z "$scriptList" ]
	then
		printErrorAndExit "No test scripts found: $testLabel"
	fi

	while IFS= read -r scriptPath || [ -n "$scriptPath" ]
	do
		[ -n "$scriptPath" ] || continue
		scriptBase=${scriptPath##*/}
		printf 'Running %s...\n' "$scriptBase"
		(
			cd "$testDir"
			if [ -x "$scriptPath" ]
			then
				"$scriptPath" "$binPath"
			else
				sh "$scriptPath" "$binPath"
			fi
		)
	done <<EOF
$scriptList
EOF
}
