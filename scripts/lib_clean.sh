#!/bin/sh

set -eu

[ -n "${__included_lib_clean_sh:-}" ] && return 0
__included_lib_clean_sh=1


. lib_paths.sh


# $1 - Project root directory.
#
# $2 - Optional style name (empty for all styles).
# ($3..n) - Optional target names.
# Cleans build and test output for all builds, or a style/target subset.
#
cleanBuilds( )
(
	projectRoot=$1
	shift

	cleanStyle=${1:-}
	shift

	if [ -n "$cleanStyle" ]
	then
		ensureValidStyleName "$cleanStyle"
	fi

	cleanTargets=""
	while [ "$#" -gt 0 ]
	do
		cleanTarget=$( resolveTargetName "$projectRoot" "$1" )
		if [ -n "$cleanTargets" ]
		then
			cleanTargets="$cleanTargets
$cleanTarget"
		else
			cleanTargets=$cleanTarget
		fi
		shift
	done

	cleanTargets=$( printf '%s\n' "$cleanTargets" \
		| awk 'NF && !seen[$0]++' )

	buildDir=$( outRootPath "$projectRoot" )
	buildsRoot=$( buildsRootPathFromBuildDir "$buildDir" )
	testsRoot=$( testsRootPathFromBuildDir "$buildDir" )

	if [ -n "$cleanStyle" ]
	then
		if [ -z "$cleanTargets" ]
		then
			rm -rf "$buildsRoot/$cleanStyle"
			rm -rf "$testsRoot/$cleanStyle"
			return 0
		fi

		while IFS= read -r cleanTarget || [ -n "$cleanTarget" ]
		do
			[ -n "$cleanTarget" ] || continue
			rm -rf "$buildsRoot/$cleanStyle/$cleanTarget"
			rm -rf "$testsRoot/$cleanStyle/$cleanTarget"
		done <<EOF
$cleanTargets
EOF
		return 0
	fi

	if [ -z "$cleanTargets" ]
	then
		rm -rf "$buildsRoot"
		rm -rf "$testsRoot"
		return 0
	fi

	cleanStyles=""
	for root in "$buildsRoot" "$testsRoot"
	do
		[ -d "$root" ] || continue
		for styleDir in "$root"/*
		do
			[ -d "$styleDir" ] || continue
			styleName=${styleDir##*/}
			if [ -n "$cleanStyles" ]
			then
				cleanStyles="$cleanStyles
$styleName"
			else
				cleanStyles=$styleName
			fi
		done
	done

	cleanStyles=$( printf '%s\n' "$cleanStyles" \
		| awk 'NF && !seen[$0]++' )

	while IFS= read -r styleName || [ -n "$styleName" ]
	do
		[ -n "$styleName" ] || continue
		while IFS= read -r cleanTarget || [ -n "$cleanTarget" ]
		do
			[ -n "$cleanTarget" ] || continue
			rm -rf "$buildsRoot/$styleName/$cleanTarget"
			rm -rf "$testsRoot/$styleName/$cleanTarget"
		done <<EOF
$cleanTargets
EOF
	done <<EOF
$cleanStyles
EOF
)
