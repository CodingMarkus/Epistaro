#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_error.sh
. lib_paths.sh
. lib_build_settings.sh
. lib_build.sh


# Prints command usage information.
#
printHelp( )
{
	_ph_text="
  run [-s[tyle] <style>] <target> [<arg> ...]

      Build a binary target (run style by default) and execute it.
      Arguments following <target> are passed to the binary.
      Only available for .bin targets.
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


case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

esac

styleName=run

while [ "$#" -gt 0 ]
do
	case "$1" in
		--help)
			printHelp
			exit 0
			;;

		-*)
			if isStyleFlag "$1"
			then
				shift
				[ "$#" -gt 0 ] || printHelpAndExit
				styleName=$1
				ensureValidStyleName "$styleName"
				shift
				continue
			fi
			printHelpAndExit
			;;

		*)
			break
			;;
	esac
done

[ "$#" -gt 0 ] || printHelpAndExit

target=$( resolveTargetName "$__projDir" "$1" )
shift

case "$target" in
	*.bin) ;;
	*) printErrorAndExit "Target is not a binary: $target" ;;
esac

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

platformRequireSupportedTarget

buildSettings=$( resolvedBuildSettings "$styleFile" )
syncStyleSetVars "$styleFile"

case "$__origDir" in
	"$__projDir"/*|"$__projDir") buildDir=$( outRootPath "$__projDir" ) ;;
	*) buildDir="$__origDir" ;;
esac

buildTarget "$__projDir" "$target" "$styleName" "$buildDir" "$buildSettings"

targetDir=$( buildTargetDirPath "$buildDir" "$styleName" "$target" )
binPath=$targetDir/$target
[ -x "$binPath" ] || printErrorAndExit "Binary not found: $binPath"

printf '\n====== Running Target %s ======\n\n' "$target"
(
	cd "$targetDir"
	"./$target" "$@"
)

printf '\n====== All Done ======\n'
