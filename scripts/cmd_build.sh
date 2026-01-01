#!/bin/sh

set -eu

scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$scriptDir/lib_cmd.sh"
initCmdPaths "$scriptDir"


# Prints command usage information.
#
printHelp( )
{
	helpText="
  build [<style> [<target> ...]]

      Build target(s) using style.
      If no target is provided, all targets are built.
      If no style is provided, all targets are built deployment style.
"
	printf '%s' "$helpText"
}


# Prints command usage to stderr and exits with failure.
#
printHelpAndExit( )
{
	printHelp >&2
	exit 1
}

. lib_error.sh
. lib_paths.sh

case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac


styleName=${1:-}
if [ -z "$styleName" ]
then
	styleName=deploy
else
	ensureValidStyleName "$styleName"
	shift
fi

styleFile=$styleName
case "$styleFile" in
	/*) ;;
	*/*.cfg|*/*) styleFile="$projDir/$styleFile" ;;
	*.cfg) styleFile="$projDir/styles/$styleFile" ;;
	*) styleFile="$projDir/styles/$styleName.cfg" ;;
esac

if [ ! -f "$styleFile" ]
then
	printErrorAndExit "Style not found: $styleFile"
fi

. lib_build_settings.sh

buildSettings=$( resolvedBuildSettings "$styleFile" )

if [ "$#" -eq 0 ]
then
	set --
	for targetDir in "$projDir"/targets/*
	do
		[ -d "$targetDir" ] || continue
		set -- "$@" "$( basename -- "$targetDir" )"
	done
	if [ "$#" -eq 0 ]
	then
		printErrorAndExit "No targets found"
	fi
else
	origTargets="$@"
	set --
	for target in $origTargets
	do
		resolvedTarget=$( resolveTargetName "$projDir" "$target" )
		set -- "$@" "$resolvedTarget"
	done
fi

. lib_build.sh

case "$origDir" in
	"$projDir"/*|"$projDir") buildDir=$( outRootPath "$projDir" );;
	*) buildDir="$origDir";;
esac

for target in "$@"
do
	buildTarget "$projDir" "$target" "$styleName" "$buildDir" \
		"$buildSettings"
done

printf '\n====== All Done ======\n'
