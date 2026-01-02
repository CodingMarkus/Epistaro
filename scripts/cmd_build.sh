#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


# Prints command usage information.
#
printHelp( )
{
	_ph_text="
  build [<style> [<target> ...]]

      Build target(s) using style.
      If no target is provided, all targets are built.
      If no style is provided, all targets are built deployment style.
"
	printf '%s' "$_ph_text"
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
	*/*.cfg|*/*) styleFile="$__projDir/$styleFile" ;;
	*.cfg) styleFile="$__projDir/styles/$styleFile" ;;
	*) styleFile="$__projDir/styles/$styleName.cfg" ;;
esac

if [ ! -f "$styleFile" ]
then
	printErrorAndExit "Style not found: $styleFile"
fi

. lib_build_settings.sh

platformRequireSupportedTarget

buildSettings=$( resolvedBuildSettings "$styleFile" )
syncStyleSetVars "$styleFile"

if [ "$#" -eq 0 ]
then
	set --
	for targetDir in "$__projDir"/targets/*
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
		resolvedTarget=$( resolveTargetName "$__projDir" "$target" )
		set -- "$@" "$resolvedTarget"
	done
fi

. lib_build.sh

case "$__origDir" in
	"$__projDir"/*|"$__projDir") buildDir=$( outRootPath "$__projDir" );;
	*) buildDir="$__origDir";;
esac

for target in "$@"
do
	buildTarget "$__projDir" "$target" "$styleName" "$buildDir" \
		"$buildSettings"
done

printf '\n====== All Done ======\n'
