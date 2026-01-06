#!/bin/sh

set -eu

__scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
. "$__scriptDir/lib_cmd.sh"
initCmdPaths "$__scriptDir"


. lib_clean.sh


# Prints command usage information.
#
printHelp( )
{
	_ph_text="
  clean [-s[tyle] <style>] [<target> ...]

      Clean all builds and tests, or only for a style/target subset.
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

# $1 - Targets list (newline separated).
#
# Prints targets, one per line, with list formatting.
#
_printTargetsList( )
{
	_ptl_list=$1

	while IFS= read -r target || [ -n "$target" ]
	do
		[ -n "$target" ] || continue
		printf '   - %s\n' "$target"
	done <<EOF
$_ptl_list
EOF
}

case "${1:-}" in
	--help)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-*)
		if isStyleFlag "$1"
		then
			:
		else
			printHelpAndExit
		fi
		;;

esac

styleName=""

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

targetsList=""
if [ "$#" -gt 0 ]
then
	for target in "$@"
	do
		resolvedTarget=$( resolveTargetName "$__projDir" "$target" )
		if [ -n "$targetsList" ]
		then
			targetsList="$targetsList
$resolvedTarget"
		else
			targetsList=$resolvedTarget
		fi
	done

	targetsList=$( printf '%s\n' "$targetsList" \
		| awk 'NF && !seen[$0]++' )

	set --
	while IFS= read -r target || [ -n "$target" ]
	do
		[ -n "$target" ] || continue
		set -- "$@" "$target"
	done <<EOF
$targetsList
EOF
else
	set --
fi

cleanBuilds "$__projDir" "$styleName" "$@" || printHelpAndExit

if [ -z "$styleName" ] && [ -z "$targetsList" ]
then
	printf 'All cleaned.\n'
elif [ -n "$styleName" ] && [ -z "$targetsList" ]
then
	printf 'All cleaned for style %s.\n' "$styleName"
elif [ -z "$styleName" ] && [ -n "$targetsList" ]
then
	printf 'All cleaned for targets:\n\n'
	_printTargetsList "$targetsList"
else
	printf 'All cleaned for style %s and targets:\n\n' "$styleName"
	_printTargetsList "$targetsList"
fi
exit 0
