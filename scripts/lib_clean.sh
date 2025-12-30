#!/bin/sh

set -eu

[ -n "${__included_lib_clean_sh:-}" ] && return 0
__included_lib_clean_sh=1

. lib_paths.sh

# $1 - Project root directory.
# ($2) - Optional style name.
# ($3) - Optional target name.
#
# Cleans build output for all builds, or a style/target subset.
#
cleanBuilds( )
(
	projectRoot=$1
	shift

	cleanStyle=${1:-}
	cleanTarget=

	if [ -n "$cleanStyle" ]
	then
		ensureValidStyleName "$cleanStyle"
		shift
		cleanTarget=${1:-}
		if [ -n "$cleanTarget" ]
		then
			ensureValidTargetName "$cleanTarget"
			shift
		fi
	fi

	if [ "$#" -ne 0 ]
	then
		return 2
	fi

	buildDir=$( outRootPath "$projectRoot" )
	cleanPath=$( buildTargetDirPath "$buildDir" "$cleanStyle" "$cleanTarget" )

	if [ -d "$cleanPath" ]
	then
		rm -rf "$cleanPath"
	fi
)
