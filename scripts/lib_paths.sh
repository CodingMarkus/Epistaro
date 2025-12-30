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

# $1 - Project root directory.
#
# Prints the builds root path.
#
# Prints the build output root path.
#
outRootPath( )
{
	projectRoot=$1

	assert "[ -n \"${projectRoot:-}\" ]" "outRootPath() missing project dir"

	printf '%s/%s\n' "$projectRoot" "$( buildOutputDirName )"
}


# $1 - Build output root directory.
#
# Prints the builds root path for a build output root.
#
buildsRootPathFromBuildDir( )
{
	buildDir=$1

	assert "[ -n \"${buildDir:-}\" ]" \
		"buildsRootPathFromBuildDir() missing build dir"

	printf '%s/%s\n' "$buildDir" "$( buildsDirName )"
}


# $1 - Project root directory.
#
# Prints the builds root path.
#
buildsRootPath( )
{
	projectRoot=$1

	assert "[ -n \"${projectRoot:-}\" ]" "buildsRootPath() missing project dir"

	buildDir=$( outRootPath "$projectRoot" )
	buildsRootPathFromBuildDir "$buildDir"
}


# $1 - Build output root directory.
# $2 - Style name.
# $3 - Target name.
#
# Prints the build target directory.
#
buildTargetDirPath( )
{
	buildDir=$1
	styleName=$2
	targetName=$3

	assert "[ -n \"${buildDir:-}\" ]" "buildTargetDirPath() missing build dir"
	assert "[ -n \"${styleName:-}\" ]" \
		"buildTargetDirPath() missing style name"
	assert "[ -n \"${targetName:-}\" ]" \
		"buildTargetDirPath() missing target name"

	buildsRoot=$( buildsRootPathFromBuildDir "$buildDir" )
	printf '%s/%s/%s\n' "$buildsRoot" "$styleName" "$targetName"
}


# $1 - Style name.
#
# Ensures style name is valid.
#
ensureValidStyleName( )
{
	styleName=$1

	assert "[ -n \"${styleName:-}\" ]" "ensureValidStyleName() missing style name"

	case "$styleName" in
		*/*) printErrorAndExit "Style name must not contain '/': $styleName" ;;
	esac
}


# $1 - Target name.
#
# Ensures target name is valid.
#
ensureValidTargetName( )
{
	targetName=$1

	assert "[ -n \"${targetName:-}\" ]" "ensureValidTargetName() missing target name"

	case "$targetName" in
		*/*) printErrorAndExit "Target name must not contain '/': $targetName" ;;
	esac
}
