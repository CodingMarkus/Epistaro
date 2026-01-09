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


# $1 - Style name.
#
# Appends the style name to the style list stored in styleNames.
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


# $1 - Project root directory.
# $2 - Style name.
#
# Resolves a style file path and ensures it exists.
#
resolveTestStyleFile( )
{
	_rsf_root=$1
	_rsf_style=$2
	_rsf_file=$_rsf_style

	case "$_rsf_file" in
		/*) ;;
		*/*.cfg|*/*) _rsf_file="$_rsf_root/$_rsf_file" ;;
		*.cfg) _rsf_file="$_rsf_root/styles/$_rsf_file" ;;
		*) _rsf_file="$_rsf_root/styles/$_rsf_style.cfg" ;;
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
# _pt_target_type.
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
# $1 - Error output path.
#
# Prints filtered error output for test failures.
#
filterTestErrorOutput( )
{
	_fte_path=${1:-}
	_fte_targets_root=${__projDir%/}/targets/
	awk -v proj="$_fte_targets_root" -v repl="targets/" '
		function replace_all(str, needle, repl,    pos) {
			while ((pos = index(str, needle)) > 0) {
				str = substr(str, 1, pos - 1) repl \
					substr(str, pos + length(needle))
			}
			return str
		}
		{
			if (proj != "") {
				$0 = replace_all($0, proj, repl)
			}
			print
		}
	' ${_fte_path:+"$_fte_path"}
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

	if [ -n "$_rtr_lib" ]
	then
		if _rtr_err=$( runTestBinary "$_rtr_path" "$_rtr_lib" 2>&1 )
		then
			_rtr_status=0
		else
			_rtr_status=$?
		fi
	else
		if _rtr_err=$( runTestBinary "$_rtr_path" 2>&1 )
		then
			_rtr_status=0
		else
			_rtr_status=$?
		fi
	fi

	if [ "$_rtr_status" -eq 0 ]
	then
		printf 'Testing %s... [' "$_rtr_label"
		printTestSuccess "PASSED"
		printf ']\n'
		return 0
	fi

	printf 'Testing %s... [' "$_rtr_label"
	printTestFailure "FAILED"
	printf ']\n'
	if [ -n "$_rtr_err" ]
	then
		printf '%s\n' "$_rtr_err" | filterTestErrorOutput
	fi
	return "$_rtr_status"
}


# $1 - Project root directory.
# $2 - Original working directory.
# $3 - Style names list, separated by newlines.
# $4.. - Target/test spec list.
#
# Builds and runs tests for the selected targets and styles.
#
runTests( )
{
	_rt_root=$1
	_rt_orig=$2
	_rt_style_names=$3
	shift 3

	platformRequireSupportedTarget
	export __style_set__TARGET __style_set__TARGET_OS __style_set__TARGET_CPU

	_rt_selections=""
	if [ "$#" -eq 0 ]
	then
		for _rt_target_dir in "$_rt_root"/targets/*
		do
			[ -d "$_rt_target_dir" ] || continue
			_rt_target=$( basename -- "$_rt_target_dir" )
			if [ -n "$_rt_selections" ]
			then
				_rt_selections="$_rt_selections
$_rt_target|"
			else
				_rt_selections="$_rt_target|"
			fi
		done
		if [ -z "$_rt_selections" ]
		then
			printErrorAndExit "No targets found"
		fi
	else
		for _rt_spec in "$@"
		do
			case "$_rt_spec" in
				*/*)
					_rt_target_part=${_rt_spec%%/*}
					_rt_selection=${_rt_spec#*/}
					[ -n "$_rt_selection" ] || printErrorAndExit \
						"Invalid test path: $_rt_spec"
					;;
				*)
					_rt_target_part=$_rt_spec
					_rt_selection=
					;;
			esac

			_rt_target=$( resolveTargetName "$_rt_root" \
				"$_rt_target_part" )

			if [ -n "$_rt_selections" ]
			then
				_rt_selections="$_rt_selections
$_rt_target|$_rt_selection"
			else
				_rt_selections="$_rt_target|$_rt_selection"
			fi
		done
	fi

	_rt_tests_to_run=""

	_rt_tmp_path=$( mktemp "${TMPDIR:-/tmp}/tests.XXXXXX" ) \
		|| printErrorAndExit "mktemp failed"

	while IFS= read -r _rt_selection_line \
		|| [ -n "$_rt_selection_line" ]
	do
		[ -n "$_rt_selection_line" ] || continue
		_rt_target=${_rt_selection_line%%|*}
		_rt_selection=${_rt_selection_line#*|}
		if [ "$_rt_selection" = "$_rt_selection_line" ]
		then
			_rt_selection=
		fi

		: > "$_rt_tmp_path"
		collectTestDirs "$_rt_root" "$_rt_target" \
			"$_rt_selection" > "$_rt_tmp_path"

		if [ ! -s "$_rt_tmp_path" ]
		then
			if [ -n "$_rt_selection" ]
			then
				printErrorAndExit \
					"No tests found for $_rt_target/$_rt_selection"
			fi
			continue
		fi

		while IFS= read -r _rt_test_rel || [ -n "$_rt_test_rel" ]
		do
			[ -n "$_rt_test_rel" ] || continue
			_rt_entry=$_rt_target\|$_rt_test_rel
			if [ -n "$_rt_tests_to_run" ]
			then
				_rt_tests_to_run="$_rt_tests_to_run
$_rt_entry"
			else
				_rt_tests_to_run=$_rt_entry
			fi
		done < "$_rt_tmp_path"
	done <<EOF
$_rt_selections
EOF

	rm -f "$_rt_tmp_path"

	_rt_tests_to_run=$( printf '%s\n' "$_rt_tests_to_run" \
		| awk 'NF && !seen[$0]++' )
	_rt_targets_to_run=$( printf '%s\n' "$_rt_tests_to_run" \
		| awk -F'|' 'NF && !seen[$1]++ { print $1 }' )

	if [ -z "$_rt_tests_to_run" ]
	then
		printf '\nNo tests found.\n'
		return 0
	fi

	case "$_rt_orig" in
		"$_rt_root"/*|"$_rt_root") _rt_build_dir=$( outRootPath "$_rt_root" ) ;;
		*) _rt_build_dir="$_rt_orig" ;;
	esac

	_rt_multiple_styles=0
	case "$_rt_style_names" in
		*"
"*) _rt_multiple_styles=1 ;;
	esac

	_rt_test_failures=0
	_rt_tests_run=0
	_rt_tests_failed=0
	while IFS= read -r _rt_style_name || [ -n "$_rt_style_name" ]
	do
		[ -n "$_rt_style_name" ] || continue

		_rt_style_file=$( resolveTestStyleFile "$_rt_root" \
			"$_rt_style_name" )
		_rt_build_settings=$( resolvedBuildSettings "$_rt_style_file" \
			"-DTESTING" )
		syncStyleSetVars "$_rt_style_file"

		if [ "$_rt_multiple_styles" -eq 1 ]
		then
			printHeader "====== Building Style $_rt_style_name ======"
		fi

		while IFS= read -r _rt_target || [ -n "$_rt_target" ]
		do
			[ -n "$_rt_target" ] || continue
			_rt_target_out_dir=$( testsTargetTargetDirPath "$_rt_build_dir" \
				"$_rt_style_name" "$_rt_target" )
			buildTarget "$_rt_root" "$_rt_target" \
				"$_rt_style_name" "$_rt_build_dir" \
				"$_rt_build_settings" "$_rt_target_out_dir"
		done <<EOF
$_rt_targets_to_run
EOF

		while IFS= read -r _rt_target || [ -n "$_rt_target" ]
		do
			[ -n "$_rt_target" ] || continue
			_rt_target_label=$( formatTargetLabel "$_rt_target" )
			printHeader "====== Building Tests for Target $_rt_target_label ======"
			printf 'Using Build Style: %s\n\n' "$_rt_style_name"
			_rt_target_had_output=0
			_rt_test_spacing_pending=0
			_rt_target_out_dir=$( testsTargetTargetDirPath "$_rt_build_dir" \
				"$_rt_style_name" "$_rt_target" )
			_rt_tests_root=$_rt_root/targets/$_rt_target/tests
			_rt_test_obj_root=$( testsTargetObjDirPath "$_rt_build_dir" \
				"$_rt_style_name" "$_rt_target" )
			_rt_test_out_dir=$( testsTargetBinDirPath "$_rt_build_dir" \
				"$_rt_style_name" "$_rt_target" )
			ensureDir "$_rt_test_obj_root"
			ensureDir "$_rt_test_out_dir"
			pruneObjectTree "$_rt_tests_root" "$_rt_test_obj_root"

			while IFS= read -r _rt_test_line || [ -n "$_rt_test_line" ]
			do
				[ -n "$_rt_test_line" ] || continue
				parseTestLine "$_rt_test_line"
				[ "$_pt_target" = "$_rt_target" ] || continue
				_rt_test_rel=$_pt_rel
				_rt_test_type=$_pt_test_type
				_rt_target_type=$_pt_target_type

				_rt_test_dir=$_rt_tests_root/$_rt_test_rel
				[ -d "$_rt_test_dir" ] || printErrorAndExit \
					"Test not found: $_rt_target/$_rt_test_rel"

				if [ "$_rt_test_type" = "it" ] \
					&& [ "$_rt_target_type" = "bin" ]
				then
					if find "$_rt_test_dir" -type f -name '*.c' \
						-print -quit | grep -q .
					then
						_err_msg="Integration test must be "
						_err_msg="${_err_msg}scripts only: "
						_err_msg="${_err_msg}$_rt_target/$_rt_test_rel"
						printErrorAndExit "$_err_msg"
					fi
					continue
				fi

				_rt_test_sanitize_settings=""
				_rt_test_compiled=0
				_rt_test_name=${_rt_test_rel%.*}
				_rt_test_label="$_rt_test_name [$_rt_test_type]"
				_rt_pre_header_spacing=0
				if [ "$_rt_test_spacing_pending" -eq 1 ]
				then
					_rt_pre_header_spacing=2
				fi
				if ! buildTestObjects "$_rt_root" "$_rt_tests_root" \
					"$_rt_test_rel" "$_rt_test_obj_root" \
					"$_rt_build_settings" _rt_test_sanitize_settings \
					_rt_test_compiled "$_rt_test_label" \
					"$_rt_pre_header_spacing"
				then
					if [ "$?" -eq 2 ]
					then
						_err_msg="No C sources found for "
						_err_msg="${_err_msg}test: "
						_err_msg="${_err_msg}$_rt_target/$_rt_test_rel"
						printErrorAndExit "$_err_msg"
					fi
					return 1
				fi
				if [ "$_rt_test_compiled" -eq 1 ]
				then
					_rt_target_had_output=1
					_rt_test_spacing_pending=1
				fi

				_rt_test_objs=$( collectTestObjects \
					"$_rt_test_obj_root" "$_rt_test_rel" )
				[ -n "$_rt_test_objs" ] \
					|| printErrorAndExit \
						"No objects found for test: $_rt_target/$_rt_test_rel"

				_rt_link_flags=$( linkFlagsFromSettings \
					"$_rt_build_settings" "$_rt_test_sanitize_settings" )

				_rt_test_bin_path=$( testBinaryPath "$_rt_test_out_dir" \
					"$_rt_test_rel" )
				case "$_rt_test_bin_path" in
					*/*) ensureDir "${_rt_test_bin_path%/*}" ;;
				esac

				if [ "$_rt_test_type" = "ut" ]
				then
					_rt_exclude_main=0
					if [ "$_rt_target_type" = "bin" ]
					then
						_rt_exclude_main=1
					fi

					_rt_target_objs=$( collectTargetObjects \
						"$_rt_build_dir" "$_rt_style_name" \
						"$_rt_target" "$_rt_exclude_main" \
						"$_rt_target_out_dir" )
					[ -n "$_rt_target_objs" ] \
						|| printErrorAndExit \
							"No target objects for $_rt_target"

					set --
					while IFS= read -r _rt_obj_path \
						|| [ -n "$_rt_obj_path" ]
					do
						[ -n "$_rt_obj_path" ] || continue
						set -- "$@" "$_rt_obj_path"
					done <<EOF
$_rt_target_objs
EOF
					while IFS= read -r _rt_obj_path \
						|| [ -n "$_rt_obj_path" ]
					do
						[ -n "$_rt_obj_path" ] || continue
						set -- "$@" "$_rt_obj_path"
					done <<EOF
$_rt_test_objs
EOF

					if isOutdated "$_rt_test_bin_path" "$@"
					then
						if [ "$_rt_test_compiled" -eq 1 ]
						then
							printf '\n'
						fi
						_rt_test_bin_name=${_rt_test_bin_path##*/}
						printf 'Linking %s [%s]...\n' \
							"$_rt_test_bin_name" "$_rt_test_type"
						linkBinary "$_rt_test_bin_path" "$_rt_root" \
							"$_rt_link_flags" "$@"
						_rt_target_had_output=1
						_rt_test_spacing_pending=1
					fi
					continue
				fi

				if [ "$_rt_test_type" = "it" ] \
					&& [ "$_rt_target_type" = "lib" ]
				then
					_rt_target_dir=$_rt_target_out_dir
					_rt_dynamic_path=$_rt_target_dir/${_rt_target%.lib}$( \
						dynamicLibExtension )
					[ -f "$_rt_dynamic_path" ] \
						|| printErrorAndExit \
							"Library not found: $_rt_dynamic_path"

					set --
					while IFS= read -r _rt_obj_path \
						|| [ -n "$_rt_obj_path" ]
					do
						[ -n "$_rt_obj_path" ] || continue
						set -- "$@" "$_rt_obj_path"
					done <<EOF
$_rt_test_objs
EOF
					set -- "$@" "$_rt_dynamic_path"

					if isOutdated "$_rt_test_bin_path" "$@"
					then
						if [ "$_rt_test_compiled" -eq 1 ]
						then
							printf '\n'
						fi
						_rt_test_bin_name=${_rt_test_bin_path##*/}
						printf 'Linking %s [%s]...\n' \
							"$_rt_test_bin_name" "$_rt_test_type"
						linkBinary "$_rt_test_bin_path" "$_rt_root" \
							"$_rt_link_flags" "$@"
						_rt_target_had_output=1
						_rt_test_spacing_pending=1
					fi
					continue
				fi

				printErrorAndExit \
					"Unsupported test type: $_rt_target/$_rt_test_rel"
			done <<EOF
$_rt_tests_to_run
EOF
			if [ "$_rt_target_had_output" -eq 1 ]
			then
				printf '\n'
			fi
			printf 'Done.\n'
		done <<EOF
$_rt_targets_to_run
EOF
	done <<EOF
$_rt_style_names
EOF

	while IFS= read -r _rt_style_name || [ -n "$_rt_style_name" ]
	do
		[ -n "$_rt_style_name" ] || continue

		_rt_style_file=$( resolveTestStyleFile "$_rt_root" \
			"$_rt_style_name" )
		syncStyleSetVars "$_rt_style_file"

		if [ "$_rt_multiple_styles" -eq 1 ]
		then
			printHeader "====== Testing Style $_rt_style_name ======"
		fi

		while IFS= read -r _rt_target || [ -n "$_rt_target" ]
		do
			[ -n "$_rt_target" ] || continue
			_rt_target_label=$( formatTargetLabel "$_rt_target" )
			printHeader "====== Running Tests for Target $_rt_target_label ======"
			_rt_target_out_dir=$( testsTargetTargetDirPath "$_rt_build_dir" \
				"$_rt_style_name" "$_rt_target" )

			while IFS= read -r _rt_test_line || [ -n "$_rt_test_line" ]
			do
				[ -n "$_rt_test_line" ] || continue
				parseTestLine "$_rt_test_line"
				[ "$_pt_target" = "$_rt_target" ] || continue
				_rt_test_rel=$_pt_rel
				_rt_test_type=$_pt_test_type
				_rt_target_type=$_pt_target_type

				_rt_tests_root=$_rt_root/targets/$_rt_target/tests
				_rt_test_dir=$_rt_tests_root/$_rt_test_rel
				[ -d "$_rt_test_dir" ] || printErrorAndExit \
					"Test not found: $_rt_target/$_rt_test_rel"

				if [ "$_rt_test_type" = "it" ] \
					&& [ "$_rt_target_type" = "bin" ]
				then
					_rt_target_dir=$_rt_target_out_dir
					_rt_bin_path=$_rt_target_dir/$_rt_target
					[ -x "$_rt_bin_path" ] || printErrorAndExit \
						"Binary not found: $_rt_bin_path"

					printf 'Running integration scripts...\n'
					_rt_tests_run=$(( _rt_tests_run + 1 ))
					if ! runIntegrationScripts "$_rt_test_dir" \
						"$_rt_bin_path" "$_rt_target/$_rt_test_rel"
					then
						_rt_test_failures=1
						_rt_tests_failed=$(( _rt_tests_failed + 1 ))
					fi
					continue
				fi

				_rt_test_out_dir=$( testsTargetBinDirPath "$_rt_build_dir" \
					"$_rt_style_name" "$_rt_target" )
				_rt_test_bin_path=$( testBinaryPath "$_rt_test_out_dir" \
					"$_rt_test_rel" )
				_rt_test_name=${_rt_test_bin_path##*/}

				if [ "$_rt_test_type" = "ut" ]
				then
					_rt_tests_run=$(( _rt_tests_run + 1 ))
					if ! runTestAndReport \
						"$_rt_test_bin_path" "$_rt_test_name"
					then
						_rt_test_failures=1
						_rt_tests_failed=$(( _rt_tests_failed + 1 ))
					fi
					continue
				fi

				if [ "$_rt_test_type" = "it" ] \
					&& [ "$_rt_target_type" = "lib" ]
				then
					_rt_target_dir=$_rt_target_out_dir
					_rt_dynamic_path=$_rt_target_dir/${_rt_target%.lib}$( \
						dynamicLibExtension )
					[ -f "$_rt_dynamic_path" ] \
						|| printErrorAndExit \
							"Library not found: $_rt_dynamic_path"

					_rt_tests_run=$(( _rt_tests_run + 1 ))
					if ! runTestAndReport \
						"$_rt_test_bin_path" "$_rt_test_name" \
						"$_rt_target_dir"
					then
						_rt_test_failures=1
						_rt_tests_failed=$(( _rt_tests_failed + 1 ))
					fi
					continue
				fi

				printErrorAndExit \
					"Unsupported test type: $_rt_target/$_rt_test_rel"
			done <<EOF
$_rt_tests_to_run
EOF
			printf 'Done.\n'
		done <<EOF
$_rt_targets_to_run
EOF
	done <<EOF
$_rt_style_names
EOF

	printf '\n%s out of %s tests passed.\n' \
		"$_rt_tests_failed" "$_rt_tests_run"

	if [ "$_rt_tests_failed" -ne 0 ]
	then
		printf '\n'
		printFailure "!!!!!! TEST FAILURES DETECTED !!!!!!"
		printf '\n'
	fi

	printHeader "====== All Done ======"
	if [ "$_rt_test_failures" -ne 0 ]
	then
		return 1
	fi

	return 0
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

	_bto_build_sanitize=$( sanitizeSettingsFromQuoted "$_bto_settings" )
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
				prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
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
				prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
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
			buildFileWithOutput "$_bto_root" "$_bto_src" \
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
				prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
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
			buildFileWithOutput "$_bto_root" "$_bto_src" \
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
				prepareFlags "$_bto_root" "$_bto_src_dir" "$_bto_settings" \
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
			buildFileWithOutput "$_bto_root" "$_bto_src" \
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
		setVar "$_bto_out_sanitize" "$_bto_target_sanitize"
	fi
	if [ -n "$_bto_out_compiled" ]
	then
		setVar "$_bto_out_compiled" "$_bto_compiled"
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
# ($5) - Optional target output directory override.
# Prints target object files.
#
collectTargetObjects( )
{
	_ctg_build=$1
	_ctg_style=$2
	_ctg_target=$3
	_ctg_exclude=${4:-0}
	_ctg_out_dir=${5:-}

	_ctg_obj_root=$( buildTargetObjSrcDirPath "$_ctg_build" \
		"$_ctg_style" "$_ctg_target" "$_ctg_out_dir" )
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
			_rtb_dyld_path="$_rtb_lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
			_rtb_ld_path="$_rtb_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
			DYLD_LIBRARY_PATH=$_rtb_dyld_path \
			LD_LIBRARY_PATH=$_rtb_ld_path \
			exec "./$_rtb_base"
		)
	else
		(
			cd "$_rtb_dir"
			exec "./$_rtb_base"
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
