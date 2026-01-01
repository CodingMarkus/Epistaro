#!/bin/sh

set -eu

[ -n "${__included_lib_list_sh:-}" ] && return 0
__included_lib_list_sh=1


. lib_assert.sh


# $1 - Project root directory.
# ($2) - Optional mode: plain.
#
# Lists available targets (one per line) and exits.
#
listTargetsAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listTargetsAndExit() missing project dir"

	projectRoot=$1
	mode=${2:-}

	[ -d "$projectRoot/targets" ] || exit 0

	targets=$( find "$projectRoot/targets" -mindepth 1 -maxdepth 1 \
		-type d -print 2>/dev/null | sed 's#.*/##' )
	[ -n "$targets" ] || exit 0

	if [ "$mode" = "plain" ]
	then
		printf '%s\n' "$targets" | awk '
			{
				base=$0
				if (sub(/\.[^.]+$/, "", base)) { }
				if (!seen[base]++) print base
			}
		'
		exit 0
	fi

	printf '\nAvailable targets:\n\n'
	printf '%s\n' "$targets" | awk '
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
# ($2) - Optional mode: plain.
#
# Lists available styles (one per line) and exits.
#
listStylesAndExit( )
{
	assert "[ -n \"${1:-}\" ]" \
		"listStylesAndExit() missing project dir"

	projectRoot=$1
	mode=${2:-}

	[ -d "$projectRoot/styles" ] || exit 0

	styles=$( find "$projectRoot/styles" -maxdepth 1 -type f \
		-name '*.cfg' -print 2>/dev/null \
		| sed -e 's#.*/##' -e 's/\.cfg$//' )
	[ -n "$styles" ] || exit 0

	if [ "$mode" = "plain" ]
	then
		printf '%s\n' "$styles"
		exit 0
	fi

	printf '\nAvailable styles:\n\n'
	printf '%s\n' "$styles" | awk '{ printf "   - %s\n", $0 }'
	exit 0
}
