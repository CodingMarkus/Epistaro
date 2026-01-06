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
		-s|-style) return 0 ;;
		*) return 1 ;;
	esac
}


# $1 - Tests root directory path.
# $2 - Suite directory path.
#
# Prints test paths within the suite, relative to the tests root.
#
_collectTestsInSuite( )
{
	_cts_root=$1
	_cts_dir=$2

	_cts_tests=""
	_cts_suites=""
	while IFS= read -r _cts_entry || [ -n "$_cts_entry" ]
	do
		[ -n "$_cts_entry" ] || continue
		_cts_base=${_cts_entry##*/}
		case "$_cts_base" in
			*.ut|*.it) _cts_tests="$_cts_tests
$_cts_entry" ;;
			*) _cts_suites="$_cts_suites
$_cts_entry" ;;
		esac
	done <<EOF
$( find "$_cts_dir" -mindepth 1 -maxdepth 1  -type d -print )
EOF

	if [ -n "$_cts_tests" ] && [ -n "$_cts_suites" ]
	then
		_cts_rel=${_cts_dir#"$_cts_root"/}
		if [ -z "$_cts_rel" ] || [ "$_cts_rel" = "$_cts_dir" ]
		then
			_cts_rel="tests"
		fi
		printErrorAndExit "Suite contains tests and sub-suites: $_cts_rel"
	fi

	if [ -n "$_cts_tests" ]
	then
		while IFS= read -r _cts_test_dir || [ -n "$_cts_test_dir" ]
		do
			[ -n "$_cts_test_dir" ] || continue
			printf '%s\n' "${_cts_test_dir#"$_cts_root"/}"
		done <<EOF
$_cts_tests
EOF
		return 0
	fi

	while IFS= read -r _cts_sub_dir || [ -n "$_cts_sub_dir" ]
	do
		[ -n "$_cts_sub_dir" ] || continue
		_collectTestsInSuite "$_cts_root" "$_cts_sub_dir"
	done <<EOF
$_cts_suites
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
	_ctd_root=$1
	_ctd_target=$2
	_ctd_sel=${3:-}

	_ctd_tests=$_ctd_root/targets/$_ctd_target/tests
	if [ ! -d "$_ctd_tests" ]
	then
		if [ -n "$_ctd_sel" ]
		then
			printErrorAndExit "Tests not found: $_ctd_target/$_ctd_sel"
		fi
		return 0
	fi

	_ctd_tests=$( stripTrailingSlash "$_ctd_tests" )
	_ctd_sel=${_ctd_sel%/}

	case "$_ctd_sel" in
		""|.) ;;
		/*|*"/../"*|*"/.."|../*|..) printErrorAndExit "Invalid test path: \
$_ctd_target/$_ctd_sel" ;;
	esac

	case "$_ctd_sel" in
		""|.)
			_collectTestsInSuite "$_ctd_tests" "$_ctd_tests"
			;;

		*.ut|*.it)
			_ctd_dir=$_ctd_tests/$_ctd_sel
			[ -d "$_ctd_dir" ] || printErrorAndExit "Test not found: \
$_ctd_target/$_ctd_sel"
			printf '%s\n' "$_ctd_sel"
			;;

		*)
			_ctd_ut=$_ctd_tests/$_ctd_sel.ut
			_ctd_it=$_ctd_tests/$_ctd_sel.it

			if [ -d "$_ctd_ut" ] && [ -d "$_ctd_it" ]
			then
				printErrorAndExit "Duplicate test name: $_ctd_target/$_ctd_sel"
			fi
			if [ -d "$_ctd_ut" ]
			then
				printf '%s.ut\n' "$_ctd_sel"
				return 0
			fi
			if [ -d "$_ctd_it" ]
			then
				printf '%s.it\n' "$_ctd_sel"
				return 0
			fi

			_ctd_suite=$_ctd_tests/$_ctd_sel
			[ -d "$_ctd_suite" ] || printErrorAndExit \
				"Test or suite not found: $_ctd_target/$_ctd_sel"
			_collectTestsInSuite "$_ctd_tests" "$_ctd_suite"
			;;
	esac
}


# $1 - Project root directory.
# $2 - Tests root directory.
# $3 - Test path relative to the tests root.
# $4 - Object output root directory.
# $5 - Quoted build settings string.
# $6 - Output variable for sanitizer settings list.
# ($7) - Optional output variable for compilation flag.
# ($8) - Optional compile label for the test header.
# ($9) - Optional blank lines to print before the test header.
#
# Builds objects for a test and updates sanitizer settings.
#
buildTestObjects( )
{
	_bto_root=$1
	_bto_tests=$2
	_bto_rel=$3
	_bto_obj_root=$4
	_bto_settings=$5
	_bto_out_sanitize=${6:-}
	_bto_out_compiled=${7:-}
	_bto_label=${8:-}
	_bto_pre_spacing=${9:-0}

	_bto_src_dir=$_bto_tests/$_bto_rel
	[ -d "$_bto_src_dir" ] \
		|| printErrorAndExit "Test source dir not found: $_bto_rel"

	_bto_src_list=$( find "$_bto_src_dir" -type f -name '*.c' -print )
	if [ -z "$_bto_src_list" ]
	then
		return 2
	fi

	_bto_build_sanitize=$( _sanitizeSettingsFromQuoted "$_bto_settings" )
	_bto_target_sanitize=""
	_bto_target_paths=""

	_bto_spacing=0
	_bto_label_printed=0
	_bto_compiled=0
	while IFS= read -r _bto_src || [ -n "$_bto_src" ]
	do
		[ -n "$_bto_src" ] || continue

		_bto_rel_path=${_bto_src#"$_bto_tests"/}
		_bto_obj_rel=${_bto_rel_path%.c}
		_bto_obj_path=$_bto_obj_root/$_bto_obj_rel.o
		_bto_dep_path=$_bto_obj_root/$_bto_obj_rel.dep

		case "$_bto_src" in
			*/*) _bto_src_dir=${_bto_src%/*} ;;
			*) _bto_src_dir="." ;;
		esac

		_bto_flags_ready=0
		_bto_work_dir=""
		_bto_file_flags=""

		if depFileIsOutdated "$_bto_dep_path"
		then
			if [ "$_bto_flags_ready" -eq 0 ]
			then
				_prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
					"$_bto_build_sanitize" "$_bto_target_sanitize" \
					"$_bto_target_paths" _bto_work_dir _bto_file_flags \
					_bto_target_sanitize _bto_target_paths
				_bto_flags_ready=1
			fi
			generateDepFile "$_bto_src" "$_bto_dep_path" \
				"$_bto_work_dir" "$_bto_file_flags"
		fi

		if isOutdated "$_bto_obj_path" "$_bto_dep_path"
		then
			if [ "$_bto_flags_ready" -eq 0 ]
			then
				_prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
					"$_bto_build_sanitize" "$_bto_target_sanitize" \
					"$_bto_target_paths" _bto_work_dir _bto_file_flags \
					_bto_target_sanitize _bto_target_paths
				_bto_flags_ready=1
			fi
			if [ "$_bto_spacing" -eq 1 ]
			then
				printf '\n'
			fi
			if [ -n "$_bto_label" ] \
				&& [ "$_bto_label_printed" -eq 0 ]
			then
				_bto_spacing_count=$_bto_pre_spacing
				while [ "$_bto_spacing_count" -gt 0 ]
				do
					printf '\n'
					_bto_spacing_count=$(( _bto_spacing_count - 1 ))
				done
				printf 'Compiling %s\n' "$_bto_label"
				printf '\n'
				_bto_label_printed=1
			fi
			printf 'Compiling %s...\n' "$_bto_rel_path"
			_bto_had_output=0
			_buildFileWithOutput "$_bto_root" "$_bto_src" \
				"$_bto_obj_path" "$_bto_work_dir" \
				"$_bto_file_flags" \
				_bto_had_output
			_bto_spacing=$_bto_had_output
			_bto_compiled=1
			continue
		fi

		set --
		while IFS= read -r _bto_dep || [ -n "$_bto_dep" ]
		do
			[ -n "$_bto_dep" ] || continue
			case "$_bto_dep" in
				/*) _bto_dep_res=$_bto_dep ;;
				*) _bto_dep_res=$_bto_src_dir/$_bto_dep ;;
			esac
			set -- "$@" "$_bto_dep_res"
		done < "$_bto_dep_path"

		if [ "$#" -eq 0 ]
		then
			if [ "$_bto_flags_ready" -eq 0 ]
			then
				_prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
					"$_bto_build_sanitize" "$_bto_target_sanitize" \
					"$_bto_target_paths" _bto_work_dir _bto_file_flags \
					_bto_target_sanitize _bto_target_paths
				_bto_flags_ready=1
			fi
			if [ "$_bto_spacing" -eq 1 ]
			then
				printf '\n'
			fi
			if [ -n "$_bto_label" ] \
				&& [ "$_bto_label_printed" -eq 0 ]
			then
				_bto_spacing_count=$_bto_pre_spacing
				while [ "$_bto_spacing_count" -gt 0 ]
				do
					printf '\n'
					_bto_spacing_count=$(( _bto_spacing_count - 1 ))
				done
				printf 'Compiling %s\n' "$_bto_label"
				printf '\n'
				_bto_label_printed=1
			fi
			printf 'Compiling %s...\n' "$_bto_rel_path"
			_bto_had_output=0
			_buildFileWithOutput "$_bto_root" "$_bto_src" \
				"$_bto_obj_path" "$_bto_work_dir" \
				"$_bto_file_flags" \
				_bto_had_output
			_bto_spacing=$_bto_had_output
			_bto_compiled=1
			continue
		fi

		if isOutdated "$_bto_obj_path" "$@"
		then
			if [ "$_bto_flags_ready" -eq 0 ]
			then
				_prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
					"$_bto_build_sanitize" "$_bto_target_sanitize" \
					"$_bto_target_paths" _bto_work_dir _bto_file_flags \
					_bto_target_sanitize _bto_target_paths
				_bto_flags_ready=1
			fi
			if [ "$_bto_spacing" -eq 1 ]
			then
				printf '\n'
			fi
			if [ -n "$_bto_label" ] \
				&& [ "$_bto_label_printed" -eq 0 ]
			then
				_bto_spacing_count=$_bto_pre_spacing
				while [ "$_bto_spacing_count" -gt 0 ]
				do
					printf '\n'
					_bto_spacing_count=$(( _bto_spacing_count - 1 ))
				done
				printf 'Compiling %s\n' "$_bto_label"
				printf '\n'
				_bto_label_printed=1
			fi
			printf 'Compiling %s...\n' "$_bto_rel_path"
			_bto_had_output=0
			_buildFileWithOutput "$_bto_root" "$_bto_src" \
				"$_bto_obj_path" "$_bto_work_dir" \
				"$_bto_file_flags" \
				_bto_had_output
			_bto_spacing=$_bto_had_output
			_bto_compiled=1
		fi
	done <<EOF
$_bto_src_list
EOF

	if [ -n "$_bto_out_sanitize" ]
	then
		_setVar "$_bto_out_sanitize" "$_bto_target_sanitize"
	fi
	if [ -n "$_bto_out_compiled" ]
	then
		_setVar "$_bto_out_compiled" "$_bto_compiled"
	fi
}


# $1 - Object output root directory.
# $2 - Test path relative to the tests root.
#
# Prints object files for a test, if any.
#
collectTestObjects( )
{
	_cto_root=$1
	_cto_rel=$2

	_cto_dir=$_cto_root/$_cto_rel
	if [ ! -d "$_cto_dir" ]
	then
		return 0
	fi

	find "$_cto_dir" -type f -name '*.o' -print
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
	_ctg_build=$1
	_ctg_style=$2
	_ctg_target=$3
	_ctg_exclude=${4:-0}

	_ctg_obj_root=$( buildTargetObjSrcDirPath "$_ctg_build" \
		"$_ctg_style" "$_ctg_target" )
	[ -d "$_ctg_obj_root" ] || return 0

	if [ "$_ctg_exclude" -eq 1 ]
	then
		find "$_ctg_obj_root" -type f -name '*.o' ! -name 'main.o' -print
	else
		find "$_ctg_obj_root" -type f -name '*.o' -print
	fi
}


# $1 - Tests target directory path.
# $2 - Test path relative to the tests root.
#
# Prints the path to the test binary.
#
testBinaryPath( )
{
	_tbp_dir=$1
	_tbp_rel=$2

	_tbp_base=${_tbp_rel##*/}
	_tbp_name=${_tbp_base%.*}

	case "$_tbp_rel" in
		*/*) printf '%s/%s/%s\n' "$_tbp_dir" "${_tbp_rel%/*}" "$_tbp_name" ;;
		*) printf '%s/%s\n' "$_tbp_dir" "$_tbp_name" ;;
	esac
}


# $1 - Test binary path.
#
# ($2) - Optional dynamic library directory.
# Runs a test binary with optional library path injection.
#
_setupCrashReporterSuppression( )
{
	case "${__style_set__TARGET_OS:-}" in
		macos)
			CRASH_REPORTER_NO_GUI=1
			CRASH_REPORTER_NO_NOTIFICATION=1
			export CRASH_REPORTER_NO_GUI CRASH_REPORTER_NO_NOTIFICATION
			;;
	esac
}

runTestBinary( )
{
	_rtb_path=$1
	_rtb_lib=${2:-}

	_rtb_dir=${_rtb_path%/*}
	_rtb_base=${_rtb_path##*/}

	if [ -n "$_rtb_lib" ]
	then
		(
			cd "$_rtb_dir"
			_setupCrashReporterSuppression
			_rtb_dyld_path="$_rtb_lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
			_rtb_ld_path="$_rtb_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
			DYLD_LIBRARY_PATH=$_rtb_dyld_path \
			LD_LIBRARY_PATH=$_rtb_ld_path \
			"./$_rtb_base"
		)
	else
		(
			cd "$_rtb_dir"
			_setupCrashReporterSuppression
			"./$_rtb_base"
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
	_ris_dir=$1
	_ris_bin=$2
	_ris_label=$3

	_ris_execs=$( find "$_ris_dir" -maxdepth 1 -type f -perm -111 -print )
	if [ -n "$_ris_execs" ]
	then
		_ris_scripts=$_ris_execs
	else
		_ris_scripts=$( find "$_ris_dir" -maxdepth 1 -type f \
			-name '*.sh' -print )
	fi

	if [ -z "$_ris_scripts" ]
	then
		printErrorAndExit "No test scripts found: $_ris_label"
	fi

	while IFS= read -r _ris_path || [ -n "$_ris_path" ]
	do
		[ -n "$_ris_path" ] || continue
		_ris_base=${_ris_path##*/}
		printf 'Running %s...\n' "$_ris_base"
		(
			cd "$_ris_dir"
			if [ -x "$_ris_path" ]
			then
				"$_ris_path" "$_ris_bin"
			else
				sh "$_ris_path" "$_ris_bin"
			fi
		)
	done <<EOF
$_ris_scripts
EOF
}
