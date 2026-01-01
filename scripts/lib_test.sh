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


isStyleFlag( )
{
	case "${1:-}" in
		-s|-st|-sty|-styl|-style) return 0 ;;
		*) return 1 ;;
	esac
}


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

	oldBuildSanitize=${buildSanitizeSettings:-}
	oldTargetSanitize=${targetSanitizeSettings:-}
	oldTargetSanitizePaths=${targetSanitizePaths:-}

	buildSanitizeSettings=$( _sanitizeSettingsFromQuoted "$buildSettings" )
	targetSanitizeSettings=""
	targetSanitizePaths=""

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

		fileFlagsReady=0

		if depFileIsOutdated "$depPath"
		then
			_prepareFlags "$projectRoot" "$srcDir" "$buildSettings"
			generateDepFile "$srcPath" "$depPath" "$workDir" \
				"$fileFlags"
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
			compileSpacing=$buildFileHadOutput
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
			compileSpacing=$buildFileHadOutput
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
			compileSpacing=$buildFileHadOutput
			compiledAny=1
		fi
	done <<EOF
$srcList
EOF

	testSanitizeSettings=$targetSanitizeSettings

	buildSanitizeSettings=$oldBuildSanitize
	targetSanitizeSettings=$oldTargetSanitize
	targetSanitizePaths=$oldTargetSanitizePaths
}


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
