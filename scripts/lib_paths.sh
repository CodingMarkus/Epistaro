#!/bin/sh

set -eu

[ -n "${__included_lib_paths_sh:-}" ] && return 0
__included_lib_paths_sh=1

. lib_assert.sh
. lib_error.sh


# Prints the name of the build output directory.
#
buildOutputDirName( )
{
	printf '%s\n' ".out"
}


# Prints the name of the builds directory.
#
buildsDirName( )
{
	printf '%s\n' "builds"
}

# Prints the name of the object directory.
#
objDirName( )
{
	printf '%s\n' "obj"
}

# Prints the build output root path.
#
outRootPath( )
{
	assert "[ -n \"${1:-}\" ]" "outRootPath() missing project dir"

	printf '%s/%s\n' "$1" "$( buildOutputDirName )"
}


# $1 - Build output root directory.
#
# Prints the builds root path for a build output root.
#
buildsRootPathFromBuildDir( )
{
	assert "[ -n \"${1:-}\" ]" \
		"buildsRootPathFromBuildDir() missing build dir"

	printf '%s/%s\n' "$1" "$( buildsDirName )"
}


# $1 - Project root directory.
#
# Prints the builds root path.
#
buildsRootPath( )
{
	assert "[ -n \"${1:-}\" ]" "buildsRootPath() missing project dir"

	buildsRootPathFromBuildDir "$( outRootPath "$1" )"
}


# $1 - Build output root directory.
# ($2) - Optional style name.
# ($3) - Optional target name.
#
# Prints the build target directory.
#
buildTargetDirPath( )
{
	assert "[ -n \"${1:-}\" ]" "buildTargetDirPath() missing build dir"

	if [ -n "${3:-}" ] && [ -z "${2:-}" ]
	then
		printErrorAndExit \
			"Target name requires style name: ${3:-}"
	fi

	if [ -z "${2:-}" ]
	then
		buildsRootPathFromBuildDir "$1"
		return 0
	fi

	if [ -z "${3:-}" ]
	then
		printf '%s/%s\n' "$( buildsRootPathFromBuildDir "$1" )" "$2"
		return 0
	fi

	printf '%s/%s/%s\n' "$( buildsRootPathFromBuildDir "$1" )" "$2" "$3"
}


# $1 - Build output root directory.
# $2 - Style name.
# $3 - Target name.
#
# Prints the object directory for a build target.
#
buildTargetObjDirPath( )
{
	assert "[ -n \"${1:-}\" ]" \
		"buildTargetObjDirPath() missing build dir"
	assert "[ -n \"${2:-}\" ]" \
		"buildTargetObjDirPath() missing style name"
	assert "[ -n \"${3:-}\" ]" \
		"buildTargetObjDirPath() missing target name"

	printf '%s/%s\n' "$( buildTargetDirPath "$1" "$2" "$3" )" \
		"$( objDirName )"
}


# $1 - Style name.
#
# Ensures style name is valid.
#
ensureValidStyleName( )
{
	assert "[ -n \"${1:-}\" ]" "ensureValidStyleName() missing style name"

	case "$1" in
		*/*) printErrorAndExit "Style name must not contain '/': $1" ;;
	esac
}


# $1 - Target name.
#
# Ensures target name is valid.
#
ensureValidTargetName( )
{
	assert "[ -n \"${1:-}\" ]" "ensureValidTargetName() missing target name"

	case "$1" in
		*/*) printErrorAndExit "Target name must not contain '/': $1" ;;
	esac
}
