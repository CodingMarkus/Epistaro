#!/bin/sh

set -eu

[ -n "${__included_lib_list_sh:-}" ] && return 0
__included_lib_list_sh=1


. lib_assert.sh


# $1 - Project root directory.
#
# ($2) - Optional mode: plain.
# Lists available targets (one per line) and exits.
#
listTargetsAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listTargetsAndExit() missing project dir"

	_lt_root=$1
	_lt_mode=${2:-}

	[ -d "$_lt_root/targets" ] || exit 0

	_lt_targets=$( find "$_lt_root/targets" -mindepth 1 -maxdepth 1 \
		-type d -print 2>/dev/null | sed 's#.*/##' )
	[ -n "$_lt_targets" ] || exit 0

	if [ "$_lt_mode" = "plain" ]
	then
		printf '%s\n' "$_lt_targets" | awk '
			{
				base=$0
				if (sub(/\.[^.]+$/, "", base)) { }
				if (!seen[base]++) print base
			}
		'
		exit 0
	fi

	printf '\nAvailable targets:\n\n'
	printf '%s\n' "$_lt_targets" | awk '
		{
			orig=$0
			base=$0
			ext=""
			if (sub(/\.[^.]+$/, "", base)) {
				ext=substr(orig, length(base)+2)
			}
			if (seen[base]++) next
			if (ext != "") {
				printf "   - %s [%s]\n", base, ext
			} else {
				printf "   - %s\n", base
			}
		}
	'
	exit 0
}


# $1 - Project root directory.
#
# ($2) - Optional mode: plain.
# Lists available styles (one per line) and exits.
#
listStylesAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listStylesAndExit() missing project dir"

	_ls_root=$1
	_ls_mode=${2:-}

	[ -d "$_ls_root/styles" ] || exit 0

	_ls_styles=$( find "$_ls_root/styles" -maxdepth 1 -type f \
		-name '*.cfg' -print 2>/dev/null \
		| sed -e 's#.*/##' -e 's/\.cfg$//' )
	[ -n "$_ls_styles" ] || exit 0

	if [ "$_ls_mode" = "plain" ]
	then
		printf '%s\n' "$_ls_styles"
		exit 0
	fi

	printf '\nAvailable styles:\n\n'
	printf '%s\n' "$_ls_styles" | awk '{ printf "   - %s\n", $0 }'
	exit 0
}


# $1 - Project root directory.
#
# ($2) - Optional target name (resolved).
# ($3) - Optional mode: plain.
# Lists available tests and exits.
#
listTestsAndExit( )
{
	assert "[ -n \"${1:-}\" ]" "listTestsAndExit() missing project dir"

	_ltt_root=$1
	_ltt_target=${2:-}
	_ltt_mode=${3:-}

	if [ "$_ltt_target" = "plain" ] && [ -z "$_ltt_mode" ]
	then
		_ltt_mode=plain
		_ltt_target=
	fi

	if [ -n "$_ltt_target" ]
	then
		_ltt_tests=$_ltt_root/targets/$_ltt_target/tests
		[ -d "$_ltt_tests" ] || exit 0

		_ltt_dirs=$( find "$_ltt_tests" -type d \
			\( -name '*.ut' -o -name '*.it' \) -print 2>/dev/null )
		[ -n "$_ltt_dirs" ] || exit 0

		if [ "$_ltt_mode" = "plain" ]
		then
			printf '%s\n' "$_ltt_dirs" \
				| sed "s#^$_ltt_tests/##" \
				| awk -v prefix="$_ltt_target/" \
					'{ path=$0; sub(/\.(ut|it)$/, "", path); print prefix path }'
			exit 0
		fi

		printf '\nAvailable tests for "%s":\n\n' "$_ltt_target"
		printf '%s\n' "$_ltt_dirs" \
			| sed "s#^$_ltt_tests/##" \
			| awk '
				{
					orig=$0
					base=$0
					ext=""
					if (sub(/\.(ut|it)$/, "", base)) {
						ext=substr(orig, length(base)+2)
					}
					if (ext != "") {
						printf "   - %s [%s]\n", base, ext
					} else {
						printf "   - %s\n", base
					}
				}
			'
		exit 0
	fi

	for _ltt_dir in "$_ltt_root"/targets/*
	do
		[ -d "$_ltt_dir" ] || continue
		_ltt_target=$( basename -- "$_ltt_dir" )
		_ltt_tests=$_ltt_dir/tests
		[ -d "$_ltt_tests" ] || continue

		_ltt_dirs=$( find "$_ltt_tests" -type d \
			\( -name '*.ut' -o -name '*.it' \) -print 2>/dev/null )
		[ -n "$_ltt_dirs" ] || continue

		if [ "$_ltt_mode" = "plain" ]
		then
			printf '%s\n' "$_ltt_dirs" \
				| sed "s#^$_ltt_tests/##" \
				| awk -v prefix="$_ltt_target/" \
					'{ path=$0; sub(/\.(ut|it)$/, "", path); print prefix path }'
			continue
		fi

		printf '\nAvailable tests for "%s":\n\n' "$_ltt_target"
		printf '%s\n' "$_ltt_dirs" \
			| sed "s#^$_ltt_tests/##" \
			| awk '
				{
					orig=$0
					base=$0
					ext=""
					if (sub(/\.(ut|it)$/, "", base)) {
						ext=substr(orig, length(base)+2)
					}
					if (ext != "") {
						printf "   - %s [%s]\n", base, ext
					} else {
						printf "   - %s\n", base
					}
				}
			'
	done
	exit 0
}
