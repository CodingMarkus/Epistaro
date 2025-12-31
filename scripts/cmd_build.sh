#!/bin/sh

set -eu

origDir=$( pwd -P )
scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
projDir=$( CDPATH='' cd -- "$scriptDir/.." && pwd -P )

cd "$scriptDir"

printHelp( )
{
	helpText="
  build [<style> [<target> ...]]

      Build target(s) using style.
      If no target is provided, all targets are build.
      If no style is provided, all targets are build deployment style.

  build -c[lean] [<style> [<target>]]

      Clean all builds, or only builds for a style and optional target.


  build -t[argets]

      List available targets.


  build -s[tyles]

      List available styles.


  build -h[elp]

      Show this help screen.
"
	printf '%s' "$helpText"
}


printHelpAndExit( )
{
	printHelp >&2
	exit 1
}

. lib_clean.sh
. lib_error.sh
. lib_list.sh
. lib_paths.sh

case "${1:-}" in
	-help|-h)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-targets|-t)
		[ "$#" -eq 1 ] || printHelpAndExit
		listTargetsAndExit "$projDir"
		;;

	-styles|-s)
		[ "$#" -eq 1 ] || printHelpAndExit
		listStylesAndExit "$projDir"
		;;

	-clean|-c)
		shift
		cleanBuilds "$projDir" "$@" || printHelpAndExit
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

buildSettings=$( buildSettingsForStyle "$styleFile" )

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
	for target in "$@"
	do
		if [ ! -d "$projDir/targets/$target" ]
		then
			printErrorAndExit "Target not found: $target"
	fi
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
